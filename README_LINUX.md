# Stock RAVA - Linux Deployment Guide

Complete guide for deploying **Stock RAVA** (Risk And Volatility Analysis Dashboard) on Linux, specifically Ubuntu 24.x.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Overview](#overview)
3. [Prerequisites](#prerequisites)
4. [Environment Setup](#environment-setup)
5. [Deployment Options](#deployment-options)
6. [Port Configuration](#port-configuration)
7. [Firewall Configuration](#firewall-configuration)
8. [Troubleshooting](#troubleshooting)
9. [Performance Optimization](#performance-optimization)
10. [Testing in WSL](#testing-in-wsl)
11. [Advanced Configuration](#advanced-configuration)
12. [Advanced: Virtual Environments (Optional)](#advanced-virtual-environments-optional)
13. [Security Considerations](#security-considerations)
14. [Uninstallation](#uninstallation)

---

## Quick Start

**For small Linux boxes - System-wide installation (no virtual environment):**

```bash
# Navigate to project directory
cd ~/stock-rava

# Make scripts executable (required first time)
chmod +x *.sh

# Note: All scripts share common functions in app_common.sh
# This ensures consistent behavior (venv detection, Python checks, etc.)

# Add ~/.local/bin to PATH (to avoid warnings and enable commands)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
export PATH="$HOME/.local/bin:$PATH"

# Upgrade pip (requires --break-system-packages on Ubuntu/Debian)
pip install --upgrade pip --break-system-packages

# Install project dependencies
pip install -r requirements_app.txt --break-system-packages

# Verify streamlit is accessible
streamlit --version

# Start the app
./start_app_background.sh

# Access at http://localhost:8501
```

**Notes:**
- The `--break-system-packages` flag is required for system-wide installation on Ubuntu/Debian
- If you see PATH warnings during installation, they're harmless - the PATH fix above ensures commands work correctly
- For production servers, consider using virtual environments (see [Advanced: Virtual Environments](#advanced-virtual-environments-optional) below)

---

## Overview

This guide covers deploying the Stock RAVA Streamlit application on Linux systems using:
- Background bash scripts (quick deployment)
- GNU Screen sessions (development)
- Systemd user services (production)

**App Name**: `Stock_RAVA.py`
- **RAVA** = Risk And Volatility Analysis
- Cross-platform Python application

**Script Structure:**
- All deployment scripts share common functions in `app_common.sh`
- Scripts automatically detect virtual environments or use system Python
- Consistent behavior across all deployment methods

---

## Prerequisites

### System Requirements

- **OS**: Linux (tested on Ubuntu 24.04 LTS)
- **Python**: 3.8 or higher (Ubuntu 24.04 includes Python 3.12)
- **Package Manager**: apt, yum, or dnf
- **Permissions**: Standard user permissions (no root required)

### Install Python (if needed)

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install python3 python3-pip python3-venv

# Verify version
python3 --version
```

---

## Environment Setup

### System-Wide Installation (Default)

For small Linux boxes, system-wide installation is the simplest approach:

```bash
cd ~/stock-rava

# Ensure PATH includes ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

# Upgrade pip
pip install --upgrade pip --break-system-packages

# Install dependencies
pip install -r requirements_app.txt --break-system-packages
```

**Note:** The `--break-system-packages` flag is required on Ubuntu/Debian for system-wide installation.

---

## Advanced: Virtual Environments (Optional)

**Note:** This section is optional. For dedicated small Linux boxes, system-wide installation (above) is simpler and sufficient.

**When to use a virtual environment:**
- Multiple projects on the same system
- Production servers where isolation is important
- Testing different package versions
- Sharing the system with other applications

#### Create Virtual Environment

**Recommended: `fintech_env` for finance projects:**

```bash
cd ~/stock-rava

# Create virtual environment named 'fintech_env'
python3 -m venv fintech_env

# Activate the virtual environment
source fintech_env/bin/activate

# Verify you're using venv Python
which python
# Should show: ~/stock-rava/fintech_env/bin/python

# Upgrade pip (best practice)
pip install --upgrade pip

# Install project dependencies
pip install -r requirements_app.txt
```

**Alternative names:**

```bash
# Project-specific venv
python3 -m venv venv

# Or hidden version
python3 -m venv .venv
```

#### Virtual Environment Detection

The Linux scripts automatically detect and use virtual environments in this order:

1. **Currently active venv** (`$VIRTUAL_ENV` environment variable)
2. **`fintech_env/`** in project root
3. **`venv/`** in project root
4. **`.venv/`** in project root
5. **System Python** (fallback)

**Verify Auto-Detection:**

```bash
# Run the test script
./test_wsl.sh

# Check step 9 - it will show if venv is detected
```

#### Managing Dependencies

**Update requirements file:**

```bash
# Activate venv first
source venv/bin/activate  # or fintech_env/bin/activate

# Generate requirements from current environment
pip freeze > requirements_app.txt

# Or add a new package
pip install some-package
pip freeze > requirements_app.txt
```

**Reinstall on another machine:**

```bash
# Create venv
python3 -m venv venv

# Activate
source venv/bin/activate

# Install all dependencies
pip install -r requirements_app.txt
```

---

## Deployment Options

### Option 1: Background Script (Quick Start)

**Best for**: Quick testing, single-user deployment

**Start the app:**
```bash
./start_app_background.sh
```

**Features:**
- Runs in background using `nohup`
- Auto-opens browser (if `xdg-open` available)
- Saves PID for easy stopping
- Logs to `stock_rava.log`
- Can close terminal window
- Auto-detects virtual environments
- Uses shared common functions from `app_common.sh`

**Stop the app:**
```bash
./stop_app.sh
```

**Check status:**
```bash
./status_app.sh
```

**Advantages:**
- ✅ Simple to use
- ✅ No additional setup
- ✅ Quick start/stop
- ✅ Works without systemd

**Limitations:**
- ❌ Won't auto-start on reboot
- ❌ No automatic restart on crash
- ❌ Manual log management

### Option 2: GNU Screen Session (Development)

**Best for**: Development, debugging, interactive sessions

**Start the app:**
```bash
./start_app_screen.sh
```

**Features:**
- Creates named screen session (`stock_rava`)
- Can detach and reattach
- See live output in terminal
- Multiple terminals can attach
- Auto-detects virtual environments
- Uses shared common functions from `app_common.sh`

**Useful Commands:**
```bash
# Reattach to session
screen -r stock_rava

# Detach from session (while attached)
# Press: Ctrl+A then D

# List all screen sessions
screen -list

# Kill session
screen -X -S stock_rava quit
```

**Advantages:**
- ✅ Interactive debugging
- ✅ See live logs
- ✅ Can detach/reattach
- ✅ Useful for development

**Limitations:**
- ❌ Session ends if terminal closes
- ❌ No auto-restart

**Screen not installed:**
```bash
# Ubuntu/Debian
sudo apt-get install screen

# CentOS/RHEL
sudo yum install screen

# Fedora
sudo dnf install screen
```

### Option 3: Systemd User Service (Production)

**Best for**: Production deployment, auto-start, reliability

**Install the service:**
```bash
./install_service.sh
```

**Features:**
- Auto-starts on user login
- Auto-restarts on crash
- Managed logs via journalctl
- Runs as user service (no root needed)
- Professional deployment
- Auto-detects and configures virtual environments

**Service Management:**
```bash
# Start service
systemctl --user start stock-rava.service

# Stop service
systemctl --user stop stock-rava.service

# Check status
systemctl --user status stock-rava.service

# Enable auto-start (on login)
systemctl --user enable stock-rava.service

# Disable auto-start
systemctl --user disable stock-rava.service

# View logs (live)
journalctl --user -u stock-rava.service -f

# View recent logs
journalctl --user -u stock-rava.service -n 50
```

**Uninstall service:**
```bash
./uninstall_service.sh
```

**Advantages:**
- ✅ Auto-start on login
- ✅ Auto-restart on failure
- ✅ Professional deployment
- ✅ Integrated logging
- ✅ System integration

**Limitations:**
- ⚠️ Requires systemd (most modern Linux distros have it)
- ⚠️ Requires user service support

**Enable lingering (if service should run when logged out):**
```bash
# For user services to run without login session
loginctl enable-linger $USER
```

---

## Port Configuration

By default, Stock RAVA runs on port **8501**.

**Change port in script:**

Edit `start_app_background.sh` and modify:
```bash
streamlit run Stock_RAVA.py --server.headless true --server.port 8502
```

**Change port in systemd service:**

Edit `~/.config/systemd/user/stock-rava.service`:
```ini
ExecStart=/usr/bin/python3 -m streamlit run ... --server.port 8502
```

**Check if port is in use:**
```bash
# Using ss (recommended - installed by default)
ss -tuln | grep :8501

# Or using netstat (requires: sudo apt install net-tools)
netstat -tuln | grep :8501

# Or using lsof
lsof -i :8501

# Kill process using port (if needed)
lsof -ti :8501 | xargs kill -9
```

---

## Firewall Configuration (Ubuntu)

If using UFW (Uncomplicated Firewall):

```bash
# Allow port 8501
sudo ufw allow 8501/tcp

# Check firewall status
sudo ufw status
```

**Note**: For local-only access (localhost), firewall changes are not needed.

---

## Troubleshooting

### App won't start

**Check Python version:**
```bash
python3 --version
# Should be 3.8 or higher
```

**Check Streamlit installation:**
```bash
streamlit --version
# If not found, install: pip install streamlit
# Or with venv: source venv/bin/activate && pip install streamlit
```

**Check port availability:**
```bash
# Check if port 8501 is in use (recommended)
ss -tuln | grep :8501
# Or using netstat (if installed)
netstat -tuln | grep :8501

# Kill process using port (if needed)
lsof -ti :8501 | xargs kill -9
```

### Background script issues

**Check if process is running:**
```bash
./status_app.sh
# Or manually
ps aux | grep streamlit
```

**Check logs:**
```bash
tail -f stock_rava.log
```

**Permission issues:**
```bash
# Make scripts executable
chmod +x *.sh

# Ensure app_common.sh is also executable (shared by all scripts)
chmod +x app_common.sh
```

### Systemd service issues

**Check if systemd user services are enabled:**
```bash
systemctl --user list-units
# Should not show errors
```

**View detailed service status:**
```bash
systemctl --user status stock-rava.service -l --no-pager
```

**Check service logs:**
```bash
# View all logs
journalctl --user -u stock-rava.service

# View recent logs (last 50 lines)
journalctl --user -u stock-rava.service -n 50

# Follow logs (live)
journalctl --user -u stock-rava.service -f
```

**Systemd service not using venv:**

Reinstall service after creating venv:
```bash
./uninstall_service.sh
./install_service.sh
```

The install script will detect and configure the venv automatically.

### Screen session issues

**Can't reattach to screen:**
```bash
# List all sessions
screen -list

# If session shows as "Attached", force detach
screen -d stock_rava

# Then reattach
screen -r stock_rava
```

### Browser won't open

**Manual browser access:**
- Background script uses `xdg-open` (Linux standard)
- If it fails, manually open: http://localhost:8501
- Works with Firefox, Chrome, Chromium, etc.

**Check if app is accessible:**
```bash
curl http://localhost:8501
# Should return HTML response
```

### PATH warnings during installation

**Warning: Scripts installed in `~/.local/bin` which is not on PATH**

If you see warnings like:
```
WARNING: The script streamlit is installed in '/home/user/.local/bin' which is not on PATH.
```

**Solutions:**

**Option 1: Add to PATH (Recommended - Already done if you followed setup)**
```bash
# Add to ~/.bashrc (persistent)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# Apply to current session
export PATH="$HOME/.local/bin:$PATH"

# Verify it works
which streamlit
streamlit --version
```

**Option 2: Suppress warnings (if PATH is already set)**
```bash
pip install -r requirements_app.txt --break-system-packages --no-warn-script-location
```

**Option 3: Ignore the warnings**
These warnings are harmless if:
- You're using `--break-system-packages` for system-wide installation
- Commands work after adding `~/.local/bin` to PATH
- The installation completed successfully

**Note:** After adding to PATH, restart your terminal or run `source ~/.bashrc` for the changes to take effect in new sessions.

### Virtual environment issues

**Scripts not detecting venv:**

Check venv exists:
```bash
ls -la | grep venv
# or
ls -la | grep fintech_env
```

Ensure scripts are executable:
```bash
chmod +x *.sh
```

Manual activation:
```bash
source venv/bin/activate  # or fintech_env/bin/activate
./start_app_background.sh
```

**Venv Python version mismatch:**

Create venv with specific Python version:
```bash
python3.12 -m venv venv
# Or
python3.11 -m venv venv
```

---

## Performance Optimization

### Virtual Environment (Optional - for production/multi-project setups)

**Create virtual environment:**
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements_app.txt
```

**Update scripts to use venv:**

Scripts auto-detect virtual environments, but you can manually activate:
```bash
source venv/bin/activate
./start_app_background.sh
```

### Resource Usage

**Typical resource usage:**
- **Memory**: ~150-200 MB
- **CPU**: Low (spikes during data processing)
- **Disk**: Minimal (cached data)

**Monitor resources:**
```bash
# While app is running
top -p $(cat stock_rava.pid)

# Or use htop
htop
```

### Performance Tips

- First run: 10-30 seconds (downloads data)
- Subsequent runs: 2-5 seconds (cached)
- Caching: 1 hour TTL for ticker data

---

## Testing in WSL

You can test the Linux deployment on Windows using WSL before deploying to a real Linux server.

### Quick Test

```bash
# 1. Open WSL terminal
wsl

# 2. Navigate to project directory
cd ~/stock-rava  # or /mnt/d/path/to/stock-rava if on Windows drive

# 3. Set up PATH and install dependencies (system-wide)
export PATH="$HOME/.local/bin:$PATH"
pip install --upgrade pip --break-system-packages
pip install -r requirements_app.txt --break-system-packages

# 4. Run test script
./test_wsl.sh

# 5. Start the app
./start_app_background.sh

# 6. Open in Windows browser
# http://localhost:8501
```

### Full WSL Testing Guide

**Note**: WSL1 doesn't support systemd. WSL2 with systemd support (Windows 11 22H2+) can use systemd.

**Check if systemd is available:**
```bash
systemctl --user list-units
```

If this works, you can test the systemd service. Otherwise, use background scripts or screen sessions.

**Access Windows files from WSL:**

The Windows file system is accessible from WSL at `/mnt/c/`, `/mnt/d/`, etc.

```bash
# If your project is at D:\stock-rava
cd /mnt/d/stock-rava

# Or copy to WSL home for better performance
cp -r /mnt/d/stock-rava ~/stock-rava
cd ~/stock-rava
```

**WSL Port Forwarding:**

WSL2 automatically forwards ports to Windows, so `localhost:8501` in Windows browser will work!

For WSL1, you may need to manually forward:
```powershell
netsh interface portproxy add v4tov4 listenport=8501 listenaddress=0.0.0.0 connectport=8501 connectaddress=<WSL_IP>
```

---

## Advanced Configuration

### Custom Streamlit Config

Create `.streamlit/config.toml`:
```toml
[server]
port = 8501
address = "127.0.0.1"  # localhost only
headless = true

[browser]
gatherUsageStats = false
```

### Environment Variables

**Set in systemd service:**

Edit `~/.config/systemd/user/stock-rava.service`:
```ini
[Service]
Environment="STREAMLIT_SERVER_PORT=8501"
Environment="PYTHONPATH=/path/to/project"
```

### Multiple Instances

Run multiple instances on different ports:
```bash
# Instance 1 (port 8501)
streamlit run Stock_RAVA.py --server.port 8501

# Instance 2 (port 8502)
streamlit run Stock_RAVA.py --server.port 8502
```

---

## Security Considerations

### User Service (Recommended)

- Runs as current user (not root)
- No elevated privileges needed
- Isolated to user session

### Network Access

- By default, app listens on `localhost` (127.0.0.1)
- Only accessible from local machine
- For remote access, configure Streamlit server settings

### File Permissions

```bash
# Scripts should be executable by owner only
chmod 700 *.sh

# Service file should be readable
chmod 644 ~/.config/systemd/user/stock-rava.service
```

---

## Uninstallation

**Remove background processes:**
```bash
./stop_app.sh
```

**Remove systemd service:**
```bash
./uninstall_service.sh
```

**Remove logs and PID files:**
```bash
rm -f stock_rava.pid stock_rava.log
```

**Remove virtual environment:**
```bash
rm -rf venv fintech_env .venv
```

---

## Comparison with Windows Deployment

| Feature | Windows | Linux |
|---------|---------|-------|
| **Background Scripts** | PowerShell (.ps1) | Bash (.sh) |
| **Service Management** | Task Scheduler | Systemd |
| **Process Management** | PowerShell Jobs | nohup/screen |
| **Logs** | File-based | Journald (systemd) or files |
| **Auto-restart** | Task Scheduler | Systemd (native) |

**Key Differences:**
- Linux uses bash scripts vs PowerShell
- Linux has native systemd service support
- Linux uses journald for centralized logging
- Both share the same `Stock_RAVA.py` application file

---

## Deployment Options Comparison

| Method | Use Case | Auto-Start | Restart on Crash |
|--------|----------|------------|-------------------|
| **Background Script** | Quick start | ❌ | ❌ |
| **Screen Session** | Development | ❌ | ❌ |
| **Systemd Service** | Production | ✅ | ✅ |

---

## Technical Stack

- **Framework**: Streamlit (web interface)
- **Data**: Yahoo Finance (yfinance)
- **Analysis**: ffn + quantstats libraries
- **Visualization**: Matplotlib
- **Processing**: Pandas + NumPy

---

## Best Practices Summary

### Environment Setup

1. ✅ **For small Linux boxes: Use system-wide installation** (simpler)
2. ✅ **Add ~/.local/bin to PATH** before installing packages
3. ✅ **Keep requirements.txt updated**
4. ✅ **For production: Consider virtual environments** (see Advanced section)

### Running the App

1. ✅ **Use background script** for quick testing
2. ✅ **Use screen session** for development/debugging
3. ✅ **Use systemd service** for production deployment
4. ✅ **All scripts auto-detect virtual environments**

### System Maintenance

1. ✅ **Check logs regularly** (`stock_rava.log` or `journalctl`)
2. ✅ **Monitor resource usage** with `top` or `htop`
3. ✅ **Keep dependencies updated** with `pip install --upgrade`
4. ✅ **Test changes in development** before production

---

## Support and Common Issues

### Common Issues

1. **Port already in use**: Stop existing instance or change port
2. **Permission denied**: Run `chmod +x *.sh`
3. **Service won't start**: Check logs with `journalctl --user -u stock-rava.service`
4. **Browser won't open**: Manually navigate to http://localhost:8501
5. **PATH warnings**: Already handled in Quick Start - commands work despite warnings

### Getting Help

- Check logs: `stock_rava.log` or `journalctl --user -u stock-rava.service`
- Verify installation: `streamlit --version`
- Check status: `./status_app.sh`
- Run test script: `./test_wsl.sh`

---

**Last Updated**: 2024
**Tested on**: Ubuntu 24.04 LTS
**Python Version**: 3.12 (default on Ubuntu 24.04)
