# nodejs_dump_app

Minimal Node.js app with a single endpoint, `GET /health`, that returns HTTP `200` and `{"status":"ok"}`. Any other path returns `404`. No npm dependencies.

Used as a PoC payload for building EC2 images: the image build clones this repo and installs `app/` as a systemd service.

## Layout

```
app/
  server.js          HTTP server, port from PORT (default 3000)
  package.json       npm start -> node server.js
  mini-app.service   systemd unit, runs /opt/mini-app/server.js as user nodeapp
```

## Requirements

- Node.js 18 or newer
- systemd (only for the service install)

## Run locally

```bash
cd app
npm start                      # or: PORT=8080 node server.js
curl -i localhost:3000/health
```

## Install as a service on a Linux host

Run on the target machine as root:

```bash
git clone https://github.com/zenki209/nodejs_dump_app.git
cd nodejs_dump_app/app

useradd -r -s /sbin/nologin nodeapp
mkdir -p /opt/mini-app
cp server.js package.json /opt/mini-app/
chown -R nodeapp:nodeapp /opt/mini-app

cp mini-app.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now mini-app

curl -i localhost:3000/health
```

The unit expects Node at `/usr/bin/node`. If `which node` prints another path, edit `ExecStart` in `mini-app.service` before copying it.

## Install with bootstrap.sh

`bootstrap.sh` (kept in the Packer project, not in this repo) automates the steps above: it installs `git` and `nodejs`, clones this repo, copies `app/` to `/opt/mini-app`, installs and starts the service, then checks `/health`.

```bash
sudo REPO_URL=https://github.com/zenki209/nodejs_dump_app.git bash bootstrap.sh
```

Optional environment variables:

| Variable       | Default         | Meaning                               |
|----------------|-----------------|---------------------------------------|
| `REPO_REF`     | `main`          | Branch or tag to clone                |
| `APP_SUBDIR`   | `app`           | Folder in this repo holding the app   |
| `INSTALL_DIR`  | `/opt/mini-app` | Install location                      |
| `SERVICE_NAME` | `mini-app`      | systemd unit name                     |
| `APP_USER`     | `nodeapp`       | User the service runs as              |

The Packer template runs the same script during the AMI build, with `repo_url`, `repo_ref` and `app_subdir` set in its variable file.

## Operate

```bash
systemctl status mini-app
journalctl -u mini-app -f
systemctl restart mini-app
```

## Change the port

Edit `Environment=PORT=3000` in `/etc/systemd/system/mini-app.service`, then run `systemctl daemon-reload && systemctl restart mini-app`. Note that `bootstrap.sh` health-checks port 3000.
