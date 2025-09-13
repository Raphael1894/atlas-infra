# 🌌 Atlas Infra

**Atlas** is a fully automated **homelab-in-a-box**.  
It turns a bare Ubuntu Server into a private core server with:

- 📦 **Storage & Collaboration** → OCIS, Gitea, Obsidian Vault sync  
- 🔒 **Security** → Vaultwarden password manager  
- 📊 **Monitoring & Metrics** → Prometheus, Grafana, Alertmanager, VictoriaMetrics  
- 📣 **Notifications** → ntfy push alerts  
- 🖥️ **Management** → Traefik, Portainer, Homepage Dashboard  
- 🌐 **Access** → LAN + Tailscale (no WAN exposure)  

All services run in **modular Docker Compose stacks**, orchestrated with a `Makefile`.  
Atlas is **reproducible**: wipe your host, rerun the installer, and you’re back online.  

---

## 🚀 Quick Start

### 1. Prepare Ubuntu Server
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git make
```

### 2. Clone this repo
```bash
git clone https://github.com/Raphael1894/atlas-infra.git
cd atlas-infra
```

### 3. Run the installer
```bash
./install.sh
```

You’ll be prompted for:
- Server **hostname** (default: `atlas`)  
- Base **domain** (default: `lan`)  
- Gitea admin user/pass/email  
- Vaultwarden admin token (auto-generated if blank)  
- Grafana admin user/pass  
- ntfy default access  

👉 Secrets are written into `.env`  
👉 Server identity is written into `server_config.env`  

At the end, Atlas will be fully bootstrapped and services will be running.  

---

## 🖥️ Services

Once installed, access your services at:

- **Homepage** → `http://<hostname>.<domain>`  
- **Portainer** → `http://portainer.<hostname>.<domain>`  
- **OCIS** → `http://cloud.<hostname>.<domain>`  
- **Gitea** → `http://git.<hostname>.<domain>`  
- **Vaultwarden** → `http://vault.<hostname>.<domain>`  
- **Grafana** → `http://grafana.<hostname>.<domain>`  
- **Prometheus** → `http://prometheus.<hostname>.<domain>`  
- **Alertmanager** → `http://alerts.<hostname>.<domain>`  
- **ntfy** → `http://ntfy.<hostname>.<domain>`  

Default base domain = `lan`.  
With hostname = `atlas`, you’d get e.g. `http://atlas.lan`.  

---

## ⚙️ Configuration

- **Server settings** → `server_config.env`  
  - Hostname, domain, data paths, timezone, Docker network  
  - Safe to commit/version  

- **Secrets** → `.env`  
  - Service admin creds & tokens  
  - ⚠️ Never commit this file (it’s in `.gitignore`)  
  - Regenerate anytime by re-running `install.sh`  

---

## 🛠 Managing Atlas

The `Makefile` provides shortcuts:

```bash
make up-core      # Start core services (proxy, dashboard, portainer)
make up-all       # Start everything
make down-all     # Stop everything
make ps           # Show running containers
make logs         # Tail logs for all containers
make restart NAME=cloud   # Restart one stack (example: cloud)
make clean        # Remove all containers, networks, and volumes
```

---

## 🔒 Security Notes

- **Vaultwarden admin token** is critical — if auto-generated, it will be shown at the end of the install. Save it securely.  
- Only LAN and Tailscale have access by default (firewall restricts external WAN access).  
- Always keep Ubuntu, Docker, and Atlas updated.  

---

## 📂 Project Structure

```
atlas-infra/
├── install.sh            # Interactive installer (entrypoint)
├── bootstrap.sh          # System setup + core services
├── server_config.env     # Server identity/config (safe to commit)
├── .env                  # Secrets (never commit, auto-generated)
├── .env.example          # Example secrets
├── Makefile              # Manage Docker stacks
├── scripts/              # Setup scripts (base, docker, tailscale, firewall, atlas)
├── proxy/                # Traefik
├── dashboard/            # Homepage
├── portainer/            # Portainer
├── cloud/                # OCIS
├── knowledge/            # Gitea + Obsidian sync
├── security/             # Vaultwarden
├── monitoring/           # Prometheus + Grafana + exporters
└── notifications/        # ntfy
```

---

## 🧪 Reproducibility

To rebuild Atlas from scratch:

```bash
# Fresh Ubuntu install
git clone https://github.com/Raphael1894/atlas-infra.git
cd atlas-infra
./install.sh
```

→ Identical environment, every time.  

---

## 🩺 Troubleshooting

If something goes wrong during installation or a service doesn’t start:

1. Run the built-in troubleshooter:
   ```bash
   ./troubleshoot.sh
   ```
   - Checks system requirements (Docker, Tailscale, firewall).  
   - Verifies all services are running.  
   - Saves logs of failing services to `logs/<service>.log`.  
   - Shows ✅ (OK) or ❌ (FAILED) with hints.

2. Open [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for detailed fixes.  
   - Common issues: Docker not starting, Tailscale not running, Vaultwarden token lost, Grafana login errors, firewall blocking LAN access.  
   - Step-by-step instructions with commands.  

👉 Beginners can rely on the `logs/` folder and TROUBLESHOOTING.md to quickly identify and fix issues.
