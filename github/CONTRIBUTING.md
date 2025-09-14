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

## 📦 Versioning & Releases

Atlas Infra uses **semantic versioning with Git tags**.  
Each version follows the format:  

```
MAJOR.MINOR.PATCH.BUILD
```

- **MAJOR** → incremented when a commit message starts with `MAJOR:` (breaking changes).  
- **MINOR** → incremented when a commit message starts with `feat:` (new features).  
- **PATCH** → incremented when a commit message starts with `fix:` (bug fixes).  
- **BUILD** → always equals the total number of commits in the repository.  

Example flow:  
- First release → `0.3.3.59` (59 commits in repo).  
- New commit with `fix:` → `0.3.3.60`.  
- New commit with `feat:` → `0.4.0.61`.  
- New commit with `MAJOR:` → `1.0.0.62`.  
- Normal commit with no prefix → `x.x.x.<commit_count>` (only BUILD changes).  

### 🛠 How to work with versions
- No need to manually create tags.  
- A GitHub Action automatically increments version numbers on **push to `main`**.  
- Each new tag creates a GitHub Release with commit history included.  

👉 **Contributor rule**: use the correct prefix (`fix:`, `feat:`, `MAJOR:`) in your commit messages to ensure proper versioning.

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

## 📌 Contributing Tips

Atlas has a dedicated [TIPS.md](../docs/TIPS.md) file where we collect small tricks, fixes, and troubleshooting notes.

If you discover a trick or a fix, add it there in the same format:

- **Symptom** → what you noticed  
- **Cause** → what’s happening behind the scenes  
- **Solution** → clear steps to fix  

This way, Atlas users can learn from each other’s setups and avoid common pitfalls.


---

✅ With these practices, Atlas Infra remains reproducible, beginner-friendly, and reliable.