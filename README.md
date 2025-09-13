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

### 3. Launch Atlas
```bash
bash atlas.sh
```

👉 This starts the **Atlas Launcher** menu.  
From there, you can choose to **install**, **bootstrap**, **check sanity**, or **troubleshoot**.  

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

- **Config templates** → `config/config-templates/`
  - `server_config.env.example` → blueprint for server identity & system paths.  
  - `.env.example` → blueprint for secrets (admin users, tokens, passwords).  

- **Server settings** → `config/server_config.env`  
  - Hostname, domain, data paths, timezone, Docker network  
  - Safe to commit/version  

- **Secrets** → `config/.env`  
  - Service admin creds & tokens  
  - ⚠️ Never commit this file (it’s in `.gitignore`)  
  - Regenerate anytime by re-running `install.sh`  

---

## 🛠 Managing Atlas

The `tools/Makefile` provides shortcuts:

```bash
make -f tools/Makefile up-core      # Start core services (proxy, dashboard, portainer)
make -f tools/Makefile up-all       # Start everything
make -f tools/Makefile down-all     # Stop everything
make -f tools/Makefile ps           # Show running containers
make -f tools/Makefile logs         # Tail logs for all containers
make -f tools/Makefile restart NAME=cloud   # Restart one stack (example: cloud)
make -f tools/Makefile clean        # Remove all containers, networks, and volumes
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
├── atlas.sh                # Root wrapper → launches tools/run.sh
├── config/               # Configs and secrets
│   ├── config-templates/ # Example blueprints for configs & secrets
│   ├── server_config.env # Active server config (safe to commit)
│   └── .env              # Secrets (never commit, auto-generated)
├── docs/                 # Contributor & troubleshooting docs
├── services/             # Modular service stacks
│   ├── proxy/            # Traefik reverse proxy
│   ├── dashboard/        # Homepage dashboard
│   ├── portainer/        # Portainer manager
│   ├── cloud/            # OCIS (Nextcloud alt)
│   ├── knowledge/        # Gitea + Obsidian sync
│   ├── security/         # Vaultwarden
│   ├── monitoring/       # Prometheus, Grafana, Alertmanager
│   ├── notifications/    # ntfy push notifications
│   └── scripts/          # System setup scripts
├── tools/                # Dev & runtime utilities
│   ├── run.sh            # Atlas Launcher (menu)
│   ├── install.sh        # Interactive installer
│   ├── bootstrap.sh      # System prep & core services
│   ├── prepare-runtime.sh# Export runtime-only folder
│   ├── sanity-check.sh   # Quick health check
│   ├── troubleshoot.sh   # Advanced troubleshooting
│   └── Makefile          # Manage Docker stacks
└── README.md             # This file
```

---

## 🧪 Reproducibility

To rebuild Atlas from scratch:

```bash
# Fresh Ubuntu install
git clone https://github.com/Raphael1894/atlas-infra.git
cd atlas-infra
./run.sh
```

→ Identical environment, every time.  

---

## 🧹 Cleaning Development Files

If you only want to keep the **runtime environment** (minimal files to run Atlas), you can run:

```bash
tools/prepare-runtime.sh
```

This will:

1. Create a `runtime/` folder with minimal configs + docker-compose files.  
2. Run a sanity check to ensure all services are healthy.  
3. Ask if you want to delete development files and keep only runtime.  

👉 Optional — keep full repo if you plan to update or contribute.

---

## 🩺 Troubleshooting

If something goes wrong:

1. Run the troubleshooter:
   ```bash
   tools/troubleshoot.sh
   ```
   - Checks system requirements (Docker, Tailscale, firewall).  
   - Verifies services are running.  
   - Saves logs of failing services into `logs/`.  

2. Run the sanity check:
   ```bash
   tools/sanity-check.sh
   ```

3. Read [TROUBLESHOOTING](./docs/TROUBLESHOOTING.md) for detailed fixes. 



## 📜 License & Maintenance

Atlas Infra is licensed under the **MIT License** — you are free to use, copy, modify, and distribute it, as long as you credit the original author.  

⚠️ **Disclaimer:** This project is provided *as-is*, without support or warranties.  
I do not provide troubleshooting or ongoing maintenance.  
Contributions, forks, and community-driven improvements are welcome.  

---

## 📚 Documentation

Atlas Infra includes several docs to help you use and contribute:

- [README](./README.md) → Main guide (you are here)  
- [CONTRIBUTING](./docs/CONTRIBUTING.md) → How to contribute and dev workflow  
- [LICENSE](./docs/LICENSE.md) → Project license (MIT)  
- [SECURITY](./docs/SECURITY.md) → Security policy (no support, community fixes only)  
- [TROUBLESHOOTING](./docs/TROUBLESHOOTING.md) → Common issues and how to fix them  

👉 Start with **bash atlas.sh** to launch the menu and explore your options.

