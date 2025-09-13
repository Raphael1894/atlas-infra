# 🛠️ Atlas Troubleshooting Guide

This guide covers the most common issues you may encounter when installing or running **Atlas Infra**.

---

## 🚑 First Step: Run the Troubleshooter

If installation failed or a service is down, run:

```bash
tools/troubleshoot.sh
```

This script will:
- Check **system requirements** (Docker, Tailscale, firewall).  
- Check that all **services are running**.  
- Save logs of failing services to `logs/<service>.log`.  
- Show ✅ (OK) or ❌ (FAILED) results with hints.  

👉 If you see failures, continue below.

---

## 🚫 Docker Issues

**Symptoms:**
- `tools/troubleshoot.sh` shows ❌ at "Docker installed" or "Docker daemon running".  
- Installer errors with: `Cannot connect to the Docker daemon`.  

**Fix:**
```bash
sudo systemctl restart docker
sudo systemctl enable docker
journalctl -u docker -n 50 --no-pager
```

If Docker is broken beyond repair:
```bash
sudo apt remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

---

## 🌐 Network / DNS Problems

**Symptoms:**
- Services like `http://atlas.lan` don’t resolve.  
- `tools/troubleshoot.sh` ❌ on "Docker network atlas_net" or "Tailscale running".  

**Fix:**
1. Ensure Docker network exists:
   ```bash
   docker network create atlas_net
   ```
2. Restart Tailscale:
   ```bash
   sudo systemctl restart tailscaled
   tailscale status
   ```

---

## 🔑 Vaultwarden Token Lost

**Symptoms:**
- Can't log into Vaultwarden admin panel.  
- `tools/troubleshoot.sh` ❌ at "Vaultwarden".  

**Fix:**
- Check `config/.env`:
  ```bash
  grep VW_ADMIN_TOKEN config/.env
  ```
- If missing, regenerate:
  ```bash
  docker compose -f services/security/docker-compose.yml down
  echo "VW_ADMIN_TOKEN=new-token" >> config/.env
  docker compose -f services/security/docker-compose.yml up -d
  ```

---

## 📊 Grafana Login Fails

**Symptoms:**
- Default login doesn’t work.  
- `tools/troubleshoot.sh` ❌ at "Grafana".  

**Fix:**
- Check `config/.env`:
  ```bash
  grep GRAFANA_ADMIN config/.env
  ```
- Reset password:
  ```bash
  docker exec -it monitoring-grafana grafana-cli admin reset-admin-password newpass
  ```

---

## 🔥 Firewall Blocking Access

**Symptoms:**
- Services unreachable on LAN.  
- `tools/troubleshoot.sh` ❌ at "Firewall active".  

**Fix:**
```bash
sudo ufw allow from 192.168.0.0/16 to any port 80,443 proto tcp
sudo ufw allow in on tailscale0
sudo ufw status
```

---

## 📦 Containers Crash or Restart

**Symptoms:**
- `tools/troubleshoot.sh` ❌ for a service.  
- Service logs in `logs/<service>.log` show errors.  

**Fix:**
1. Inspect logs:
   ```bash
   less logs/<service>.log
   ```
2. Check `config/.env` and `config/server_config.env` for wrong values.  
3. Verify file permissions → PUID/PGID in `server_config.env` must match your user.  

---

## 🧹 Reset Atlas

If too many things are broken:

```bash
make -f tools/Makefile down-all
make -f tools/Makefile clean
./run.sh
```

⚠️ This wipes containers, networks, and volumes. Backups in `/srv/atlas-backups` are safe.

---

## 📡 Still Stuck?

1. Check the logs saved by `tools/troubleshoot.sh` in the `logs/` folder.  
2. Manually view logs:
   ```bash
   docker logs <container_name> --tail=100 -f
   ```
3. Check system logs:
   ```bash
   journalctl -xe
   ```

Then consult this guide or rebuild from scratch.
