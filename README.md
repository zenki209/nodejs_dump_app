# nodejs_dump_app

Minimal Node.js app with a single endpoint, `GET /health`, that returns HTTP `200` and `{"status":"ok"}`. Any other path returns `404`. No npm dependencies.

Used as a PoC payload for building EC2 images: the image build clones this repo and installs `app/` as a systemd service.

## Layout

```
app/
  server.js          HTTP server, port from PORT (default 3000)
  package.json       npm start -> node server.js
  mini-app.service   systemd unit, runs /opt/mini-app/server.js as user nodeapp
  bootstrap.sh       installs the app folder it sits in as a systemd service
```

## Requirements

- Ubuntu (tested on 24.04) with `apt`
- Node.js 18 or newer (`bootstrap.sh` installs it)
- systemd (only for the service install)

## Run locally

```bash
cd app
npm start                      # or: PORT=8080 node server.js
curl -i localhost:3000/health
```

## Install as a service on a Linux host

Clone the repo and run `bootstrap.sh` as root:

```bash
git clone https://github.com/zenki209/nodejs_dump_app.git
sudo bash nodejs_dump_app/app/bootstrap.sh
```

`bootstrap.sh`:

1. installs `nodejs` and `curl` with `apt`
2. creates the system user `nodeapp` if missing
3. copies the folder it lives in (`app/`) to `/opt/mini-app`
4. installs `mini-app.service` into systemd, enables it and restarts it
5. calls `http://localhost:3000/health` up to 10 times; exits `1` and prints the service log if it never gets `200`

Running it again redeploys the code and restarts the service. After install, `/opt/mini-app/bootstrap.sh` can also be re-run in place.

To deploy a new version on an existing host:

```bash
cd nodejs_dump_app && git pull && sudo bash app/bootstrap.sh
```

## Build an AMI with Packer

The Packer project clones this repo in EC2 user data and runs `app/bootstrap.sh` during the image build, so the AMI boots with the service already enabled. Branch or tag is chosen with its `repo_ref` variable.

## Operate

```bash
systemctl status mini-app
journalctl -u mini-app -f
systemctl restart mini-app
```

## Change the port

Edit `Environment=PORT=3000` in `/etc/systemd/system/mini-app.service`, then run `systemctl daemon-reload && systemctl restart mini-app`. Note that `bootstrap.sh` health-checks port 3000.
