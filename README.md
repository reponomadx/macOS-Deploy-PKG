<img src="reponomadx-logo.jpg" alt="reponomadx logo" width="250"/></img>
# 📦 Remote macOS PKG Deployment Tool

![Platform](https://img.shields.io/badge/platform-macOS-blue)
![Shell](https://img.shields.io/badge/shell-bash-brightgreen)
![License](https://img.shields.io/badge/license-MIT-yellow)
![Status](https://img.shields.io/badge/stability-stable-success)

This Bash-based tool automates the secure remote deployment of `.pkg` installer files across multiple macOS hosts via SSH. It is ideal for environments where centralized software pushes are required — such as deploying internal tools, agents, or configuration packages across lab or fleet machines.

---

## 🔧 Features

* Deploys any `.pkg` file to multiple Macs remotely.
* Uses `sshpass` and `rsync` for efficient and secure file transfer.
* Automatically:

  * Creates the target directory on remote Macs.
  * Installs the `.pkg` using `sudo installer`.
  * Cleans up the installer file afterward.
* Tracks and reports:

  * ✅ Successful installs
  * ❌ Failed installs
  * ⚠️ Skipped (invalid) hosts

---

## 🧹 Requirements

* macOS or Linux system with:

  * `bash`
  * `sshpass`
  * `rsync`
* SSH access to all remote hosts
* Local `.pkg` installer file
* A plain text file listing hostnames or IPs (one per line)

---

## 📂 File Structure

```
deploy_pkg.sh         # Main deployment script
your_installer.pkg    # The .pkg file to deploy
hosts.txt             # List of target Mac hostnames or IP addresses
```

---

## ⚙️ Configuration

Before running, edit `deploy_pkg.sh` and replace placeholder values:

```bash
PKG_PATH="path/to/your_installer.pkg"
HOSTS_FILE="path/to/hosts.txt"
REMOTE_PKG_DIR="/tmp/pkgdeploy"
SSH_USER="your_ssh_username"
SSH_PASS=$(security find-generic-password -a "your_ssh_account" -w)
```

---

## 🚀 Usage

1. Make the script executable:

```bash
chmod +x deploy_pkg.sh
```

2. Run the script:

```bash
./deploy_pkg.sh
```

---

## ✅ Example hosts.txt

```
macbook1.local
10.0.1.45
macmini-dev.acme.org
```

---

## 🔐 Security Note

This script uses the macOS Keychain (`security find-generic-password`) to retrieve the SSH password. To store the password in Keychain:

```bash
security add-generic-password -a "your_ssh_account" -s "SSH Password" -w
```

For added security, consider switching to SSH key-based authentication in production.

---

## 📝 Deployment Summary

At the end of each run, a detailed report is printed:

```
===== 📋 Deployment Summary =====
✅ Successful installs: 3
❌ Failed installs: 1
⚠️ Skipped hosts: 2
==================================
```

---

## 💡 Tips

* To test connectivity and credentials, try:
  `sshpass -p "$SSH_PASS" ssh $SSH_USER@host`
* To install `sshpass` on macOS via Homebrew:
  `brew install hudochenkov/sshpass/sshpass`

---

## 📄 License

MIT License
© 2025 Brian Irish

---
