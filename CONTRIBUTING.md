# 🤝 Contributing to Atlas Infra

Thank you for your interest in contributing to **Atlas Infra**!  
This project aims to provide a reproducible, modular, and private homelab server.

---

## 🧩 Project Philosophy

- **Reproducibility** → A bare Ubuntu + this repo = fully working Atlas server.  
- **Modularity** → Each service is isolated in its own Docker Compose stack.  
- **Automation** → Setup should require minimal manual configuration.  
- **Security-first** → LAN + Tailscale only, no WAN exposure by default.  

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

Each service lives in its own folder with a `docker-compose.yml` file.  

---

## 🚀 Adding a New Service

1. **Create a new folder** under the repo root, e.g. `myservice/`.  
2. Add a **`docker-compose.yml`** for the service.  
3. If the service needs environment variables:  
   - Add defaults to `.env.example`.  
   - Add prompts in `install.sh` if user input is required.  
4. Update the **Makefile**:  
   - Add `$(COMPOSE) -f myservice/docker-compose.yml up -d` under `up-all`.  
   - Add teardown entry in `down-all`.  
5. Update the **README.md** → list the service in "Services" and "Project Structure".  

---

## 🔧 Coding Style & Scripts

- Use **bash** (`#!/usr/bin/env bash`) with `set -euo pipefail`.  
- All setup logic belongs in `scripts/` (e.g. `docker.sh`, `tailscale.sh`).  
- All scripts should be **idempotent** → running them twice should not break anything.  
- Use **colored output** (`GREEN`, `RED`, `YELLOW`, `CYAN`) for clarity.  

---

## 🔒 Secrets Management

- Secrets go into `.env`.  
- Never commit `.env`.  
- Use `.env.example` to document default values.  
- `install.sh` should handle generating or prompting for secrets.  

---

## 🧪 Testing Changes

1. Spin up a fresh Ubuntu VM (or LXC container).  
2. Clone your branch.  
3. Run `./install.sh`.  
4. Verify:  
   - All services come up.  
   - You can access the dashboard + key services.  
   - Monitoring shows healthy system.  

---

## 📜 Submitting Contributions

- Fork the repo & create a feature branch.  
- Follow the coding guidelines above.  
- Update docs (`README.md`, `TROUBLESHOOTING.md`) if needed.  
- Open a Pull Request with a clear description of your changes.  

---

## 🙌 Community Guidelines

- Keep discussions friendly and constructive.  
- Focus on stability, automation, and reproducibility.  
- Respect security: avoid exposing services unnecessarily.  

---
