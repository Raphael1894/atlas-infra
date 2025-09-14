# 🌌 Atlas Infra

**Atlas** is a fully automated **homelab-in-a-box**.  
It turns a bare Ubuntu Server into a private core server with:

- 📦 **Storage & Collaboration** → OCIS, Gitea, Obsidian Vault sync (via CouchDB LiveSync)  
- 🔒 **Security** → Vaultwarden password manager  
- 📊 **Monitoring & Metrics** → Prometheus, Grafana, Alertmanager, VictoriaMetrics  
- 📣 **Notifications** → ntfy push alerts  
- 🖥️ **Management** → Traefik, Portainer, Homepage Dashboard  
- 🌐 **Access** → LAN + Tailscale (no WAN exposure)  

All services run in **modular Docker Compose stacks**, orchestrated with a `Makefile`.  
Atlas is **reproducible**: wipe your host, rerun the installer, and you’re back online.  

---

## 🌐 Prerequisite: Tailscale Domain

Atlas requires a **resolvable base domain** to expose its services.  
We strongly recommend using a **Tailscale tailnet domain**.

### Why?

- `lan` or `.local` hostnames will **not resolve reliably** across devices.  
- Tailscale provides a globally accessible, secure DNS domain (`tailnet-1234.ts.net`).  
- This ensures Atlas services like Gitea, Vaultwarden, Grafana, etc. are accessible from all your devices.

### How to get your tailnet domain

1. Go to the [Tailscale admin console](https://login.tailscale.com).  
2. Open **DNS settings**.  
3. Enable **MagicDNS**.  
4. Copy your tailnet domain (looks like `tailnet-1234.ts.net`).  
   - If you’ve set up a **custom domain**, you can use that instead.

### During Install

When prompted for `BASE_DOMAIN`, enter your tailnet domain. Example:

```
Hostname: atlas
Base domain: tailnet-1234.ts.net
```

→ Your services will be available at:

- Homepage → http://atlas.tailnet-1234.ts.net/
- Gitea → http://atlas.tailnet-1234.ts.net/gitea
- Vaultwarden → http://atlas.tailnet-1234.ts.net/vault
- Grafana → http://atlas.tailnet-1234.ts.net/grafana

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

- **Homepage** → `http://<hostname>.<domain>/`
- **Portainer** → `http://<hostname>.<domain>/portainer`
- **OCIS** → `http://<hostname>.<domain>/ocis`
- **Gitea** → `http://<hostname>.<domain>/gitea`
- **CouchDB** → `http://<hostname>.<domain>/couchdb` (used by Obsidian LiveSync plugin)
- **Vaultwarden** → `http://<hostname>.<domain>/vault`
- **Grafana** → `http://<hostname>.<domain>/grafana`
- **Prometheus** → `http://<hostname>.<domain>/prometheus`
- **Alertmanager** → `http://<hostname>.<domain>/alerts`
- **ntfy** → `http://<hostname>.<domain>/ntfy`

---

## ⚙️ Configuration

- **Config templates** → `config/config-templates/`
  - `server_config.env.template` → blueprint for server identity & system paths.  
  - `.env.template` → blueprint for secrets (admin users, tokens, passwords).  

- **Server settings** → `config/server_config.env`  
  - Hostname, domain, data paths, timezone, Docker network  
  - Safe to commit/version  

- **Secrets** → `config/.env`  
  - Service admin creds & tokens  
  - ⚠️ Never commit this file (it’s in `.gitignore`)  
  - Regenerate anytime by re-running `install.sh`  

- **CouchDB**  
  - Used by Obsidian LiveSync plugin for real-time vault sync  
  - Credentials stored in `config/.env` (`COUCHDB_USER` / `COUCHDB_PASSWORD`)

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

- CouchDB credentials are required by the Obsidian LiveSync plugin. Keep them private.  
- If you use Obsidian across multiple devices, configure LiveSync with:
  - **Server URL**: `http://<hostname>.<domain>/couchdb`
  - **Username / Password**: from your `.env` file

---

## 📂 Project Structure

```
atlas-infra/
├── atlas.sh                 # Root wrapper → launches Atlas Launcher
├── config/                  # Configs and secrets
│   ├── config-templates/    # Example blueprints (safe to copy)
│   ├── server_config.env    # Active server config (safe to commit)
│   └── .env                 # Secrets (never commit, auto-generated)
├── docs/                    # Documentation
│   └── TROUBLESHOOTING.md
├── .github/                 # Community & GitHub metadata
│   ├── CONTRIBUTING.md
│   ├── CODE_OF_CONDUCT.md
│   ├── ISSUE_TEMPLATE.md
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── SECURITY.md
├── services/                # Modular service stacks (Docker Compose)
│   ├── proxy/               # Traefik reverse proxy
│   ├── dashboard/           # Homepage dashboard
│   │   ├── docker-compose.yml
│   │   └── homepage/        # Homepage config & runtime data
│   │       ├── homepage.yaml   # Dashboard definition
│   │       └── data/           # Homepage generated settings & cache
│   ├── portainer/           # Portainer manager
│   ├── cloud/               # OCIS (storage & collaboration)
│   ├── knowledge/           # Gitea + Obsidian sync
│   ├── security/            # Vaultwarden password manager
│   ├── monitoring/          # Prometheus, Grafana, Alertmanager
│   ├── notifications/       # ntfy push notifications
│   └── scripts/             # System setup scripts (firewall, tailscale, etc.)
└── tools/                   # Dev & runtime utilities
    ├── run.sh               # Atlas Launcher (menu)
    ├── install.sh           # Interactive installer
    ├── bootstrap.sh         # System prep & core services
    ├── prepare-runtime.sh   # Export runtime-only folder
    ├── sanity-check.sh      # Quick health check
    ├── troubleshoot.sh      # Advanced troubleshooting
    ├── network.sh           # Network setup helper
    ├── colors.sh            # Shared color codes for scripts
    └── Makefile             # Manage Docker stacks
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

## 📝 Obsidian Vault Sync (LiveSync)

Atlas includes [CouchDB](https://couchdb.apache.org/), which powers the **Obsidian LiveSync plugin**.  

👉 Setup:

1. Install the **Obsidian LiveSync** community plugin.  
2. In plugin settings, enter your Atlas CouchDB details:  
   - Server URL: `http://<hostname>.<domain>/couchdb`  
   - Username / Password: from your Atlas `.env`  
3. Open your vault on any device → edits sync instantly.  

✨ This provides Dropbox/iCloud-like sync for Obsidian, but fully self-hosted.

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

---

## 📜 License & Maintenance

Atlas Infra is licensed under the **MIT License** — you are free to use, copy, modify, and distribute it, as long as you credit the original author.  

⚠️ **Disclaimer:** This project is provided *as-is*, without support or warranties.  
I do not provide troubleshooting or ongoing maintenance.  
Contributions, forks, and community-driven improvements are welcome.  

---

## 📚 Documentation

Atlas Infra includes several docs to help you use and contribute:

- [README](./README.md) → Main guide (you are here)  
- [CONTRIBUTING](./.github/CONTRIBUTING.md) → How to contribute and dev workflow  
- [LICENSE](./LICENSE) → Project license (MIT)  
- [SECURITY](./.github/SECURITY.md) → Security policy (no support, community fixes only)  
- [CODE_OF_CONDUCT](./.github/CODE_OF_CONDUCT.md) → Community rules and expected behavior  
- [TROUBLESHOOTING](./docs/TROUBLESHOOTING.md) → Common issues and how to fix them  

👉 Start with **bash atlas.sh** to launch the menu and explore your options.
