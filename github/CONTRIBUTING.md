# 🤝 Contributing to Atlas Infra

Thank you for considering contributing to **Atlas Infra**!  
Atlas is meant to be a **homelab-in-a-box**: modular, reproducible, and beginner-friendly.  
This guide explains how to set up your dev environment, coding style, and how to contribute safely.

---

## 📂 Project Philosophy

- **Modular** → Each service in its own folder (`proxy/`, `cloud/`, `monitoring/`, etc.)  
- **Reproducible** → Fresh Ubuntu + installer = identical environment  
- **Beginner-friendly** → Scripts handle complexity, docs explain troubleshooting  
- **Safe** → Secrets in `config/.env` (never committed), configs in `config/server_config.env`  

---

## 🛠 Development Workflow

1. **Clone the repo**
   ```bash
   git clone https://github.com/Raphael1894/atlas-infra.git
   cd atlas-infra
   ```

2. **Atlas installer (dev mode)**
   ```bash
   ./atlas.sh
   ```
   - Starts the **Atlas Launcher** menu  
   - Use option **1** → Install Atlas  
   - Creates `config/.env` with secrets (ignored by git)  
   - Configures `config/server_config.env` (safe to commit)  
   - Brings up all services  

3. **Manage services**
   ```bash
   make -f tools/Makefile up-all
   make -f tools/Makefile down-all
   make -f tools/Makefile restart NAME=cloud
   ```

4. **Test changes**
   - Add or update a service stack (`services/<stack>/docker-compose.yml`)  
   - Update the `tools/Makefile` if needed  
   - Run `tools/sanity-check.sh` to ensure everything is still healthy  
   - Run `tools/troubleshoot.sh` if you hit errors  

---

## 🧪 Sanity & Troubleshooting

- **Sanity check**
  ```bash
  tools/sanity-check.sh
  ```
  Ensures Docker, network, and containers are healthy.

- **Troubleshooting**
  ```bash
  tools/troubleshoot.sh
  ```
  Collects logs, checks firewall, Docker, Tailscale, and services.

---

## 🧹 Runtime Preparation

After development, you can prepare a **runtime-only folder**:

```bash
tools/prepare-runtime.sh
```

This will:
- Create `runtime/` with only configs, compose files, and minimal Makefile  
- Run a sanity check before allowing cleanup  
- Ask if you want to remove dev files and keep only runtime  

👉 Keep dev files if you’re contributing. Use cleanup only for production deployments.

---

## 🔒 Secrets & Safety

- Never commit `config/.env` (contains passwords/tokens).  
- `config/server_config.env` is safe to commit (identity + paths).  
- Always test changes in a VM or dedicated test environment before production.

---

## 📜 Coding & Style Guidelines

- **Scripts** → Bash, `set -euo pipefail`, consistent colors for output.  
- **Docker Compose** → One service stack per folder, minimal overrides.  
- **Makefile** → Keep it clean and modular. Only shortcuts to compose stacks.  
- **Docs** → Update `README.md` and `TROUBLESHOOTING.md` when adding/updating features.  

---

## 📥 Pull Requests

- Fork the repo, create a feature branch, and open a PR.  
- Include a clear description of the change.  
- Ensure `tools/install.sh`, `tools/sanity-check.sh`, and `tools/prepare-runtime.sh` work end-to-end.  
- Update documentation for any new features or changes.  

---

✅ With these practices, Atlas Infra remains reproducible, beginner-friendly, and reliable.
