#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR=/opt/mini-app
SERVICE_NAME=mini-app
APP_USER=nodeapp
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$EUID" -ne 0 ]; then
  echo "run as root" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get -o DPkg::Lock::Timeout=300 update -y
apt-get -o DPkg::Lock::Timeout=300 install -y nodejs curl

id "$APP_USER" >/dev/null 2>&1 || useradd -r -s /sbin/nologin "$APP_USER"

mkdir -p "$INSTALL_DIR"
if [ "$SRC_DIR" != "$INSTALL_DIR" ]; then
  cp -r "$SRC_DIR"/. "$INSTALL_DIR"/
fi
chown -R "$APP_USER:$APP_USER" "$INSTALL_DIR"

cp "$INSTALL_DIR/$SERVICE_NAME.service" "/etc/systemd/system/$SERVICE_NAME.service"
systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl restart "$SERVICE_NAME"

for _ in $(seq 1 10); do
  curl -fsS localhost:3000/health && exit 0
  sleep 1
done
echo "health check failed" >&2
journalctl -u "$SERVICE_NAME" --no-pager -n 50 >&2
exit 1
