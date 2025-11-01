# Stock RAVA - Linux Deployment Guide

Complete guide for deploying **Stock RAVA** (Risk And Volatility Analysis Dashboard) on Linux, specifically Ubuntu 24.x.

## Overview

This guide covers deploying the Stock RAVA Streamlit application on Linux systems using:
- Background bash scripts (quick deployment)
- GNU Screen sessions (development)
- Systemd user services (production)

**App Name**: `Stock_RAVA.py` (shared with Windows deployment)
- **RAVA** = Risk And Volatility Analysis
- Cross-platform Python application

## Prerequisites

### System Requirements
- **OS**: Linux (tested on Ubuntu 24.04 LTS)
- **Python**: 3.8 or higher (Ubuntu 24.04 includes Python 3.12)
- **Package Manager**: apt, yum, or dnf
- **Permissions**: Standard user permissions (no root required)

### ⚠️ Important: Use Virtual Environment (Recommended)

**Best Practice**: Use a virtual environment to keep system Python clean.

**Quick Setup:**
```bash
# Create virtual environment (recommended: fintech_env)
python3 -m venv fintech_env

# Activate it
source fintech_env/bin/activate

# Install dependencies
pip install -r requirements_app.txt
```

**Why?**
- ✅ Keeps Ubuntu's native Python 3.12.7 clean
- ✅ Isolates project dependencies
- ✅ Prevents conflicts with system packages
- ✅ Easy to recreate or remove

**All deployment scripts automatically detect and use virtual environments!**

See [`SETUP_VENV.md`](SETUP_VENV.md) for complete virtual environment guide.

### Install Python (if needed)
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install python3 python3-pip python3-venv

# Verify version
python3 --version
```

### Install Dependencies

**With Virtual Environment (Recommended):**
```bash
# Navigate to project directory (linux subdirectory)
cd /mnt/d/poc/Fintec/boom_bust/linux

# Create venv
python3 -m venv fintech_env
source fintech_env/bin/activate

# Install dependencies
pip install -r requirements_app.txt
```

**Without Virtual Environment (Not Recommended):**
```bash
# Only if you must use system Python
pip3 install -r requirements_app.txt
# ⚠️ This will modify system Python packages
```

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
```

## Firewall Configuration (Ubuntu)

If using UFW (Uncomplicated Firewall):

```bash
# Allow port 8501
sudo ufw allow 8501/tcp

# Check firewall status
sudo ufw status

# If firewall is enabled and blocking, you may need to allow the port
```

**Note**: For local-only access (localhost), firewall changes are not needed.

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
# If not found, install: pip3 install streamlit
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
```

### Systemd service issues

**Check if systemd user services are enabled:**
```bash
systemctl --user list-units
# Should not show errors
```

**Enable lingering (if service should run when logged out):**
```bash
# For user services to run without login session
loginctl enable-linger $USER
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

**Screen not installed:**
```bash
# Ubuntu/Debian
sudo apt-get install screen

# CentOS/RHEL
sudo yum install screen

# Fedora
sudo dnf install screen
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

## Performance Optimization

### Virtual Environment (Recommended)

**Create virtual environment:**
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements_app.txt
```

**Update scripts to use venv:**
Edit `linux/start_app_background.sh`:
```bash
# Activate venv before running
source "$PROJECT_ROOT/venv/bin/activate"
streamlit run Stock_RAVA.py ...
```

### Resource Usage

**Typical resource usage:**
- **Memory**: ~150-200 MB
- **CPU**: Low (spikes during data processing)
- **Disk**: Minimal (cached data)

**Monitor resources:**
```bash
# While app is running
top -p $(cat linux/stock_rava.pid)

# Or use htop
htop
```

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
chmod 700 linux/*.sh

# Service file should be readable
chmod 644 ~/.config/systemd/user/stock-rava.service
```

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

## Testing in WSL (Windows Subsystem for Linux)

You can test the Linux deployment on Windows using WSL before deploying to a real Linux server.

**Quick Test:**
```bash
# Run the test script
./test_wsl.sh

# If all checks pass, start the app
./start_app_background.sh

# Open in Windows browser
# http://localhost:8501
```

**Full WSL Testing Guide:**
See `TEST_WSL.md` for complete instructions on testing in WSL.

## Support and Additional Resources

### Documentation
- Main README: `../README_APP.md` (if exists in parent directory)
- Quick Start: `QUICK_START_LINUX.md`
- WSL Testing Guide: `TEST_WSL.md`
- Virtual Environment: `SETUP_VENV.md`

### Common Issues
1. **Port already in use**: Stop existing instance or change port
2. **Permission denied**: Run `chmod +x *.sh`
3. **Service won't start**: Check logs with `journalctl --user -u stock-rava.service`
4. **Browser won't open**: Manually navigate to http://localhost:8501

### Getting Help
- Check logs: `stock_rava.log` or `journalctl --user -u stock-rava.service`
- Verify installation: `streamlit --version`
- Check status: `./status_app.sh`

---

**Last Updated**: 2024
**Tested on**: Ubuntu 24.04 LTS
**Python Version**: 3.12 (default on Ubuntu 24.04)

