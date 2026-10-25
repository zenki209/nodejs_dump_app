# nodejs_dump_app

Minimal Node.js app with one endpoint, `GET /health`, returning HTTP 200.

- `app/server.js` - HTTP server (port from `PORT`, default 3000)
- `app/mini-app.service` - systemd unit, expects the app in `/opt/mini-app`

Installed on a host by the `bootstrap.sh` script, which clones this repo and installs `app/` as a systemd service.
