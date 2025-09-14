
# 🛠 Atlas Tips & Tricks

This page collects common issues you might encounter while running Atlas, along with quick fixes.  
Think of it as a **cookbook of practical solutions** for your homelab.  

---

## 📦 Homepage shows less free disk space than expected

**Symptom:**  
Homepage shows only ~90 GB free, but your SSD is 512 GB.  

**Cause:**  
By default, Ubuntu LVM only allocates ~100 GB to `/` (root).  
The rest of the SSD is unallocated inside the volume group.  

**How to check:**  
Run:
```bash
df -h
```
If `/` (root) is around 100 GB, you’re affected.

**Solution:**  
Expand the root volume to use the rest of the SSD:

```bash
# 1. Check how much free space is in the volume group
sudo vgdisplay

# 2. Expand root logical volume to use all free space
sudo lvextend -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv

# 3. Resize the filesystem
sudo resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv

# 4. Verify
df -h
```

Now `/` should show close to your full SSD size.  

---

## 📌 Contributing Tips

If you discover a trick or a fix, add it here in the same format:  

- **Symptom** → what you noticed  
- **Cause** → what’s happening behind the scenes  
- **Solution** → clear steps to fix  

This way, Atlas users can learn from each other’s setups and avoid common pitfalls.  
