#!/usr/bin/env bash
# Deploy OpenWA ke VPS Ubuntu/Debian cukup dengan IP + akses SSH (password atau key).
# Ringan: VPS hanya pull image jadi (tidak build), SQLite, engine Baileys (tanpa Chromium).
#
#   ./deploy/vps/deploy.sh <ip-vps> [user]      # user default: root
#
# Jalankan ulang perintah yang sama untuk update ke image terbaru; data & API key tetap.
# Opsional lewat env:
#   IMAGE=ghcr.io/ahmadrenhoran/openwa:main   image lain (default: image resmi OpenWA)
#   PORT=2785                                 port publik
#   ENGINE=whatsapp-web.js                    engine untuk instalasi pertama (default: baileys)
#   SSH_PORT=22
set -euo pipefail

HOST="${1:?Pakai: $0 <ip-vps> [user]}"
TARGET="${2:-root}@$HOST"
IMAGE="${IMAGE:-ghcr.io/rmyndharis/openwa:latest}"
PORT="${PORT:-2785}"
ENGINE="${ENGINE:-baileys}"
DIR="$(cd "$(dirname "$0")" && pwd)"

# Satu koneksi SSH dipakai ulang, jadi password hanya ditanya sekali.
SSH=(ssh -p "${SSH_PORT:-22}" -o StrictHostKeyChecking=accept-new
  -o ControlMaster=auto -o ControlPath="$HOME/.ssh/openwa-deploy-%C" -o ControlPersist=120)
"${SSH[@]}" -fN "$TARGET"
trap '"${SSH[@]}" -O exit "$TARGET" 2>/dev/null || true' EXIT

echo "==> Kirim file ke $TARGET"
"${SSH[@]}" "$TARGET" 'rm -rf /tmp/openwa-deploy && mkdir -p /tmp/openwa-deploy'
for f in docker-compose.yml remote.sh; do
  "${SSH[@]}" "$TARGET" "cat > /tmp/openwa-deploy/$f" < "$DIR/$f"
done

SUDO=""
[ "${2:-root}" = root ] || SUDO="sudo"
"${SSH[@]}" -t "$TARGET" "$SUDO env IMAGE='$IMAGE' PORT='$PORT' ENGINE='$ENGINE' PUBLIC_HOST='$HOST' \
  bash /tmp/openwa-deploy/remote.sh; rc=\$?; rm -rf /tmp/openwa-deploy; exit \$rc"
