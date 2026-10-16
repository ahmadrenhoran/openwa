#!/usr/bin/env bash
# Deploy OpenWA ke VPS Ubuntu/Debian cukup dengan IP + password root.
# Ringan: VPS hanya pull image jadi (tidak build), SQLite, engine Baileys (tanpa Chromium).
# Aman: HTTPS untuk IP (Let's Encrypt via Caddy), login SSH dipindah ke key lalu password dimatikan,
# firewall cuma buka SSH/80/443, update keamanan OS otomatis.
#
#   ./deploy/vps/deploy.sh <ip-vps> [user]      # user default: root
#
# Password hanya ditanya saat pertama kali; setelah itu login pakai key ~/.ssh/openwa_vps.
# Jalankan ulang perintah yang sama untuk update ke image terbaru; data & API key tetap.
# Opsional lewat env:
#   IMAGE=ghcr.io/ahmadrenhoran/openwa:main   image lain (default: image resmi OpenWA)
#   ENGINE=whatsapp-web.js                    engine untuk instalasi pertama (default: baileys)
#   API_KEY=...                               API key admin awal, min. 32 karakter (default: acak)
#   SSH_PORT=22
# Dari GitHub Actions: lihat .github/workflows/deploy-vps.yml.
set -euo pipefail

HOST="${1:?Pakai: $0 <ip-vps> [user]}"
USER_NAME="${2:-root}"
TARGET="$USER_NAME@$HOST"
IMAGE="${IMAGE:-ghcr.io/rmyndharis/openwa:latest}"
ENGINE="${ENGINE:-baileys}"
API_KEY="${API_KEY:-}"
SSH_PORT="${SSH_PORT:-22}"
DIR="$(cd "$(dirname "$0")" && pwd)"
KEY="$HOME/.ssh/openwa_vps"

# Nilai-nilai ini disisipkan ke perintah remote di dalam tanda kutip, jadi batasi karakternya.
[[ "$IMAGE" =~ ^[A-Za-z0-9./:@_-]+$ ]] || { echo "IMAGE tidak valid: $IMAGE" >&2; exit 1; }
[[ "$ENGINE" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "ENGINE tidak valid: $ENGINE" >&2; exit 1; }
if [ -n "$API_KEY" ] && ! [[ "$API_KEY" =~ ^[A-Za-z0-9_-]{32,}$ ]]; then
  echo "API_KEY minimal 32 karakter, hanya huruf/angka/_/-." >&2
  exit 1
fi
# Log GitHub Actions bisa dibaca publik; jangan cetak API key di sana.
SHOW_API_KEY=1
if [ "${GITHUB_ACTIONS:-}" = true ]; then SHOW_API_KEY=0; fi

if [ ! -f "$KEY" ]; then
  echo "==> Buat SSH key khusus VPS: $KEY"
  ssh-keygen -q -t ed25519 -N '' -C "openwa-deploy" -f "$KEY"
fi

BASE=(ssh -p "$SSH_PORT" -i "$KEY" -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new)
# Satu koneksi SSH dipakai ulang, jadi password (kalau masih perlu) hanya ditanya sekali.
SSH=("${BASE[@]}" -o ControlMaster=auto -o ControlPath="$HOME/.ssh/openwa-deploy-%C" -o ControlPersist=120)
"${SSH[@]}" -fN "$TARGET"
trap '"${SSH[@]}" -O exit "$TARGET" 2>/dev/null || true' EXIT

echo "==> Pasang SSH key di VPS"
"${SSH[@]}" "$TARGET" 'umask 077; mkdir -p ~/.ssh; touch ~/.ssh/authorized_keys
  k=$(cat); grep -qxF "$k" ~/.ssh/authorized_keys || echo "$k" >> ~/.ssh/authorized_keys' < "$KEY.pub"

# Password SSH baru dimatikan kalau login pakai key terbukti jalan lewat koneksi baru.
HARDEN_SSH=0
if "${BASE[@]}" -o ControlPath=none -o BatchMode=yes -o PreferredAuthentications=publickey "$TARGET" true 2>/dev/null; then
  HARDEN_SSH=1
else
  echo "!! Login pakai key gagal; login password SSH dibiarkan aktif."
fi

echo "==> Kirim file ke $TARGET"
"${SSH[@]}" "$TARGET" 'rm -rf /tmp/openwa-deploy && mkdir -p /tmp/openwa-deploy'
for f in docker-compose.yml Caddyfile remote.sh; do
  "${SSH[@]}" "$TARGET" "cat > /tmp/openwa-deploy/$f" < "$DIR/$f"
done

SUDO=""
[ "$USER_NAME" = root ] || SUDO="sudo"
"${SSH[@]}" -t "$TARGET" "$SUDO env IMAGE='$IMAGE' ENGINE='$ENGINE' PUBLIC_HOST='$HOST' SSH_PORT='$SSH_PORT' \
  HARDEN_SSH='$HARDEN_SSH' API_KEY='$API_KEY' SHOW_API_KEY='$SHOW_API_KEY' \
  bash /tmp/openwa-deploy/remote.sh; rc=\$?; rm -rf /tmp/openwa-deploy; exit \$rc"

# Cek dari luar: server seharusnya tidak lagi menawarkan login password.
methods=$("${BASE[@]}" -o ControlPath=none -o BatchMode=yes -o PubkeyAuthentication=no "$TARGET" true 2>&1 || true)
if grep -qE 'password|keyboard-interactive' <<<"$methods"; then
  echo "!! Login SSH pakai password masih aktif."
else
  echo "==> Login SSH pakai password sudah mati. Masuk VPS: ssh -i $KEY $TARGET"
fi

# Cek HTTPS dari luar (sertifikat pertama biasanya terbit dalam beberapa detik).
echo "==> Tunggu HTTPS https://$HOST"
for _ in $(seq 1 30); do
  if curl -fsS --max-time 5 "https://$HOST/api/health/ready" >/dev/null 2>&1; then
    echo "==> Siap: buka https://$HOST lalu login dengan API key di atas."
    exit 0
  fi
  sleep 4
done
echo "!! HTTPS belum bisa diakses. Pastikan port 80/443 tidak diblokir firewall/security group"
echo "   di panel provider VPS, lalu cek: ssh -i $KEY $TARGET 'cd /opt/openwa && docker compose logs caddy'"
exit 1
