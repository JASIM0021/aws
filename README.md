

# 📘 Server Setup Scripts (Ubuntu + Amazon Linux)

This repository contains **two fully automated server setup scripts** designed for quick deployment on **Ubuntu/Debian** and **Amazon Linux/CentOS/RHEL** environments.

These scripts help you quickly set up production-ready environments for running Node.js applications with Nginx, SSL, PM2, Bun, and more.

---

## 📁 Files Included

### **1️⃣ setup.sh**

A universal server setup script that installs:

* Node.js (LTS)
* Bun
* PM2 (process manager)
* Nginx
* Build tools
* Git, curl, unzip
* Auto Nginx reverse proxy (port 80 → 3000)

**Supports:** Ubuntu, Debian, Amazon Linux 2, CentOS, RHEL

---

### **2️⃣ setup_nginx_ssl.sh**

A universal script that sets up:

* Nginx
* Reverse proxy for your backend
* Free SSL via Let’s Encrypt (Certbot)
* Auto-renewal cron job
* Works with both `apt` and `yum` systems

**Supports:** Ubuntu, Debian, Amazon Linux 2, CentOS, RHEL

---

## 🚀 How to Run These Scripts Directly (Recommended)

You can run the scripts **directly from GitHub** using either `curl` or `wget`.

### **Run `setup.sh`**

```bash
curl -fsSL https://raw.githubusercontent.com/JASIM0021/aws/refs/heads/main/setup.sh | sudo bash
```

### **Run `setup_nginx_ssl.sh`**

```bash
curl -fsSL https://raw.githubusercontent.com/JASIM0021/aws/refs/heads/main/setup_nginx_ssl.sh | sudo bash
```

> 🔥 **No need to clone the repo.**
> ✔ Safe download flags (`-fsSL`) prevent partial or corrupted downloads.

---

## 📥 Alternative: Download First, Then Execute

```bash
curl -o setup.sh https://raw.githubusercontent.com/JASIM0021/aws/refs/heads/main/setup.sh
chmod +x setup.sh
sudo ./setup.sh
```

```bash
curl -o setup_nginx_ssl.sh https://raw.githubusercontent.com/JASIM0021/aws/refs/heads/main/setup_nginx_ssl.sh
chmod +x setup_nginx_ssl.sh
sudo ./setup_nginx_ssl.sh
```
---

## 🛠 Features Included

### ✔ For **setup.sh**

* Auto OS detection (`apt` or `yum`)
* Node.js LTS installation
* Bun installation with PATH auto-persistence
* PM2 installation for production apps
* Nginx installation + reverse proxy → `localhost:3000`
* Build tools for compiling dependencies

---

### ✔ For **setup_nginx_ssl.sh**

* Auto OS detection
* Auto Nginx installation
* Auto domain-based Nginx config creation
* Let's Encrypt SSL (Certbot)
* Certbot auto-renew (cron job)
* Backend proxy pass to any port

---

## 🏗 Requirements

* Root access (`sudo`)
* A domain name (for SSL script)
* DNS A record pointing to your server IP

---

## 📜 License

This project is licensed under the **MIT License**.
You are free to use, modify, and distribute these scripts.

---

## 🤝 Contributing

Pull requests are welcome.
If you have improvements or want to add more automated server tools, feel free to contribute.

---

