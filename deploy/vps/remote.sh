#!/usr/bin/env bash
# Dijalankan DI VPS oleh deploy.sh (sebagai root). Aman diulang: data dan .env yang ada tidak ditimpa,
# hanya OPENWA_IMAGE dan API_PORT yang diperbarui.
set -euo pipefail

APP_DIR=/opt/openwa
SRC="$(cd "$(dirname "$0")" && pwd)"
IMAGE="${IMAGE:?}"
PORT="${PORT:?}"
ENGINE="${ENGINE:?}"

log() { printf '\n==> %s\n' "$*"; }

if ! command -v curl >/dev/null; then
  log "Install curl"
  apt-get update -qq && apt-get install -y -qq curl
fi

if ! command -v docker >/dev/null; then
  log "Install Docker"
  curl -fsSL https://get.docker.com | sh
fi
docker compose version >/dev/null 2>&1 || { echo "Plugin 'docker compose' tidak ditemukan." >&2; exit 1; }

# VPS kecil (<2 GB RAM) tanpa swap gampang kena OOM saat pull/start; tambah swap 2 GB sekali saja.
mem_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
if [ "$mem_kb" -lt 2000000 ] && ! swapon --show --noheadings | grep -q .; then
  log "Buat swap 2 GB (RAM $((mem_kb / 1024)) MB)"
  if fallocate -l 2G /swapfile 2>/dev/null && chmod 600 /swapfile && mkswap /swapfile >/dev/null && swapon /swapfile; then
    grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
  else
    rm -f /swapfile
    echo "Swap tidak bisa dibuat (VPS jenis container?), lanjut tanpa swap."
  fi
fi

log "Siapkan $APP_DIR"
mkdir -p "$APP_DIR/data"
install -m 644 "$SRC/docker-compose.yml" "$APP_DIR/docker-compose.yml"

if [ ! -f "$APP_DIR/.env" ]; then
  key=$(od -An -tx1 -N24 /dev/urandom | tr -d ' \n')
  cat > "$APP_DIR/.env" <<EOF
# OpenWA — ubah sesuai kebutuhan lalu: cd $APP_DIR && docker compose up -d
OPENWA_IMAGE=$IMAGE
API_PORT=$PORT
OPENWA_MEM_LIMIT=1g

NODE_ENV=production
TZ=Asia/Jakarta
LOG_LEVEL=info

# Baileys = tanpa Chromium, paling hemat RAM. Ganti ke whatsapp-web.js kalau butuh fiturnya
# (lebih berat, naikkan OPENWA_MEM_LIMIT ke 2g).
ENGINE_TYPE=$ENGINE
BAILEYS_MARK_ONLINE_ON_CONNECT=false
AUTO_START_SESSIONS=true

DATABASE_TYPE=sqlite
STORAGE_TYPE=local

# API key admin awal (hanya dipakai saat boot pertama).
API_MASTER_KEY=$key

# Wajib false karena diakses lewat http://IP:PORT tanpa HTTPS (kalau true dashboard blank putih).
CSP_UPGRADE_INSECURE_REQUESTS=false
EOF
  chmod 600 "$APP_DIR/.env"
else
  sed -i "s|^OPENWA_IMAGE=.*|OPENWA_IMAGE=$IMAGE|; s|^API_PORT=.*|API_PORT=$PORT|" "$APP_DIR/.env"
fi

if command -v ufw >/dev/null && ufw status | grep -q 'Status: active'; then
  log "Buka port $PORT di ufw"
  ufw allow "$PORT/tcp" >/dev/null
fi

log "Pull image & jalankan"
cd "$APP_DIR"
docker compose pull
docker compose up -d --remove-orphans
docker image prune -f >/dev/null

log "Tunggu OpenWA siap"
for _ in $(seq 1 60); do
  if curl -fsS "http://127.0.0.1:$PORT/api/health/ready" >/dev/null 2>&1; then
    printf '\nOpenWA jalan.\n  Dashboard     : http://%s:%s\n  API key awal  : %s\n' \
      "${PUBLIC_HOST:-$(hostname -I | awk '{print $1}')}" "$PORT" "$(grep '^API_MASTER_KEY=' .env | cut -d= -f2-)"
    exit 0
  fi
  sleep 3
done

echo "OpenWA belum siap setelah 3 menit. Log terakhir:" >&2
docker compose logs --tail 50 >&2
exit 1
