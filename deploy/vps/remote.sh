#!/usr/bin/env bash
# Dijalankan DI VPS oleh deploy.sh (sebagai root). Aman diulang: data dan .env yang ada tidak ditimpa,
# hanya OPENWA_IMAGE, PUBLIC_HOST dan BASE_URL yang diperbarui.
set -euo pipefail

APP_DIR=/opt/openwa
SRC="$(cd "$(dirname "$0")" && pwd)"
IMAGE="${IMAGE:?}"
ENGINE="${ENGINE:?}"
PUBLIC_HOST="${PUBLIC_HOST:?}"
SSH_PORT="${SSH_PORT:-22}"

log() { printf '\n==> %s\n' "$*"; }
set_env() {
  if grep -q "^$1=" "$APP_DIR/.env"; then sed -i "s|^$1=.*|$1=$2|" "$APP_DIR/.env"; else echo "$1=$2" >> "$APP_DIR/.env"; fi
}

export DEBIAN_FRONTEND=noninteractive
need=()
command -v curl >/dev/null || need+=(curl)
command -v ufw >/dev/null || need+=(ufw)
dpkg -s unattended-upgrades >/dev/null 2>&1 || need+=(unattended-upgrades)
if [ ${#need[@]} -gt 0 ]; then
  log "Install ${need[*]}"
  apt-get update -qq && apt-get install -y -qq "${need[@]}" >/dev/null
fi

# Update keamanan OS otomatis tiap hari.
[ -f /etc/apt/apt.conf.d/20auto-upgrades ] || printf '%s\n' \
  'APT::Periodic::Update-Package-Lists "1";' 'APT::Periodic::Unattended-Upgrade "1";' \
  > /etc/apt/apt.conf.d/20auto-upgrades

# Login SSH hanya pakai key (deploy.sh sudah memastikan key-nya bisa dipakai sebelum ini jalan).
if [ "${HARDEN_SSH:-0}" = 1 ]; then
  conf=/etc/ssh/sshd_config.d/00-openwa-hardening.conf
  if grep -qiE '^\s*Include\s+/etc/ssh/sshd_config\.d/\*\.conf' /etc/ssh/sshd_config; then
    log "Matikan login SSH pakai password"
    printf '%s\n' 'PasswordAuthentication no' 'KbdInteractiveAuthentication no' \
      'PermitRootLogin prohibit-password' > "$conf"
    mkdir -p /run/sshd # `sshd -t` butuh ini; di Ubuntu 22.10+ (ssh.socket) belum tentu ada
    if sshd -t 2>/dev/null; then
      systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || true
    else
      rm -f "$conf"
      echo "!! Konfigurasi sshd ditolak, login password TIDAK dimatikan."
    fi
  else
    echo "!! sshd_config tidak memuat sshd_config.d, login password TIDAK dimatikan otomatis."
  fi
fi

if ! command -v docker >/dev/null; then
  log "Install Docker"
  curl -fsSL https://get.docker.com | sh
fi
docker compose version >/dev/null 2>&1 || { echo "Plugin 'docker compose' tidak ditemukan." >&2; exit 1; }

# Firewall: cuma SSH (dibatasi laju untuk menahan brute force), HTTP dan HTTPS.
log "Firewall (ufw): buka SSH $SSH_PORT, 80, 443"
ufw limit "$SSH_PORT/tcp" >/dev/null
ufw allow 80/tcp >/dev/null
ufw allow 443 >/dev/null
ufw --force enable >/dev/null

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
mkdir -p "$APP_DIR/data" "$APP_DIR/caddy"
install -m 644 "$SRC/docker-compose.yml" "$APP_DIR/"
# Ditimpa di tempat (inode tetap), karena Caddy me-mount file ini langsung.
cat "$SRC/Caddyfile" > "$APP_DIR/Caddyfile"

if [ ! -f "$APP_DIR/.env" ]; then
  key="${API_KEY:-$(od -An -tx1 -N24 /dev/urandom | tr -d ' \n')}"
  cat > "$APP_DIR/.env" <<EOF
# OpenWA — ubah sesuai kebutuhan lalu: cd $APP_DIR && docker compose up -d
OPENWA_IMAGE=$IMAGE
PUBLIC_HOST=$PUBLIC_HOST
BASE_URL=https://$PUBLIC_HOST
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

# Caddy (HTTPS) ada di depan: percayai X-Forwarded-For dari jaringan Docker supaya IP klien asli terbaca.
TRUSTED_PROXIES=172.16.0.0/12

# API key admin awal (hanya dipakai saat boot pertama). Simpan di password manager.
API_MASTER_KEY=$key
EOF
  chmod 600 "$APP_DIR/.env"
else
  set_env OPENWA_IMAGE "$IMAGE"
  set_env PUBLIC_HOST "$PUBLIC_HOST"
  set_env BASE_URL "https://$PUBLIC_HOST"
fi

log "Pull image & jalankan"
cd "$APP_DIR"
docker compose pull
docker compose up -d --remove-orphans
docker compose restart caddy >/dev/null 2>&1 # muat ulang Caddyfile; sertifikat tetap tersimpan
docker image prune -f >/dev/null

log "Tunggu OpenWA siap"
ready=0
for _ in $(seq 1 60); do
  curl -fsS http://127.0.0.1:2785/api/health/ready >/dev/null 2>&1 && { ready=1; break; }
  sleep 3
done
if [ "$ready" != 1 ]; then
  echo "OpenWA belum siap setelah 3 menit. Log terakhir:" >&2
  docker compose logs --tail 50 openwa >&2
  exit 1
fi

printf '\nOpenWA jalan.\n  Dashboard     : https://%s\n' "$PUBLIC_HOST"
if [ "${SHOW_API_KEY:-1}" = 1 ]; then
  printf '  API key awal  : %s\n\n' "$(grep '^API_MASTER_KEY=' .env | cut -d= -f2-)"
else
  printf '  API key awal  : (tidak dicetak) secret OPENWA_API_KEY, atau baca API_MASTER_KEY di %s/.env\n\n' "$APP_DIR"
fi
