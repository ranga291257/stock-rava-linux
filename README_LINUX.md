# Stock RAVA - Linux Deployment Guide

Complete guide for deploying **Stock RAVA** (Risk And Volatility Analysis Dashboard) on Linux, specifically Ubuntu 24.x.

## Table of Contents

### For End Users 👥
1. [Quick Start - Using the Desktop Icon](#quick-start---using-the-desktop-icon) 🖱️
2. [Operations - Managing Background Processes](#operations---managing-background-processes) ⚙️
3. [First Time Setup](#first-time-setup) 🚀

### For Developers & Administrators 👨‍💻
4. [Technical Overview](#technical-overview)
5. [Deployment Methods Explained](#deployment-methods-explained)
6. [Background vs Foreground Processes](#background-vs-foreground-processes)
7. [System Architecture](#system-architecture)
8. [Advanced Configuration](#advanced-configuration)
9. [Troubleshooting & Debugging](#troubleshooting--debugging)

### Reference 📚
10. [Port Configuration](#port-configuration)
11. [Firewall Configuration](#firewall-configuration)
12. [Virtual Environments](#virtual-environments-optional)
13. [Security Considerations](#security-considerations)
14. [Uninstallation](#uninstallation)

---

## Quick Start - Using the Desktop Icon 🖱️

**For users who just want to click an icon and use the app:**

### What You Need to Know

Stock RAVA is a **web application** that runs in the background on your computer. To use it:

1. **Make sure it's running** (see [Operations](#operations---managing-background-processes) below)
2. **Click the desktop icon** "Stock RAVA" in your application menu
3. **Your browser opens** to http://localhost:8501
4. **Use the dashboard** to analyze stocks

### Is the App Running?

**Check if it's running:**
```bash
cd ~/stock-rava
./status_app.sh
```

**If it says "RUNNING"**: ✅ You're good! Click the icon.

**If it says "NOT RUNNING"**: You need to start it first (see [Operations](#operations---managing-background-processes) below).

### Best Setup: Auto-Start on Boot

**Want it to always be ready?** Set it up **once** to start automatically:

```bash
cd ~/stock-rava
./install_service.sh
loginctl enable-linger $USER
```

**Important:** This is a **one-time setup**. After running these commands:
- ✅ The service is **installed** (creates systemd service file)
- ✅ The service is **enabled** (will start on boot)
- ✅ The app will **start automatically** when your PC boots
- ✅ Always be ready when you click the icon
- ✅ Restart automatically if it crashes

**That's it!** Now you can just click the icon anytime - even after rebooting.

**Note:** If you just installed the service, you may need to start it once manually:
```bash
systemctl --user start stock-rava.service
```
After that, it will start automatically on every boot.

---

## Operations - Managing Background Processes ⚙️

**Understanding how Stock RAVA runs and how to manage it:**

### What is a Background Process?

Stock RAVA runs as a **background process** - it runs on your computer even when you're not looking at it. Think of it like a web server that's always ready to serve the dashboard when you click the icon.

### How Background Processes Work

1. **The app starts** → Runs in the background (you don't see it in a terminal)
2. **It listens on port 8501** → Waiting for your browser to connect
3. **You click the icon** → Browser connects to http://localhost:8501
4. **Dashboard loads** → You see the Stock RAVA interface

### Starting the Background Process

**Option 1: Manual Start (Quick)**
```bash
cd ~/stock-rava
./start_app_background.sh
```
- Starts the app in the background
- Saves process ID (PID) for easy stopping
- Logs to `stock_rava.log`
- **Note:** Won't auto-start on reboot

**Option 2: Auto-Start Service (Recommended)**

**One-time setup:**
```bash
cd ~/stock-rava
./install_service.sh        # Installs the service (one-time)
loginctl enable-linger $USER # Enables boot-time start (one-time)
systemctl --user start stock-rava.service  # Start it now (first time)
```

**What this does:**
- **`./install_service.sh`** - Creates the systemd service file (one-time installation)
- **`loginctl enable-linger`** - Allows service to start on boot even without login
- **`systemctl --user start`** - Starts the service now (first time only)

**After setup:**
- ✅ Starts automatically on boot (no manual start needed)
- ✅ Restarts automatically if it crashes
- ✅ Managed by systemd (Linux service manager)
- **Best for:** Always-on setup

**Note:** The service installation is a **one-time setup**. Once installed and enabled, it will start automatically on every boot. You don't need to run `install_service.sh` again.

### Checking if the Process is Running

```bash
cd ~/stock-rava
./status_app.sh
```

**What you'll see:**
- ✅ **RUNNING** - Process is active, icon will work
- ❌ **NOT RUNNING** - Need to start it first
- ⚠️ **UNKNOWN** - No process found

**Detailed check:**
```bash
# Check process status
./status_app.sh

# Check if port 8501 is listening
ss -tuln | grep :8501

# View what's happening (logs)
tail -f stock_rava.log
```

### Stopping the Background Process

**If using manual start:**
```bash
cd ~/stock-rava
./stop_app.sh
```

**If using systemd service:**
```bash
systemctl --user stop stock-rava.service
```

### Viewing Logs (What's Happening)

**Manual start logs:**
```bash
cd ~/stock-rava
tail -f stock_rava.log
```

**Systemd service logs:**
```bash
journalctl --user -u stock-rava.service -f
```

### Common Operations

| Task | Command |
|------|---------|
| **Start app** | `./start_app_background.sh` |
| **Stop app** | `./stop_app.sh` |
| **Check status** | `./status_app.sh` |
| **View logs** | `tail -f stock_rava.log` |
| **Start service** | `systemctl --user start stock-rava.service` |
| **Stop service** | `systemctl --user stop stock-rava.service` |
| **Service status** | `systemctl --user status stock-rava.service` |

### Troubleshooting: Icon Doesn't Work

**If clicking the icon doesn't open the app:**

1. **Check if app is running:**
   ```bash
   cd ~/stock-rava
   ./status_app.sh
   ```

2. **If not running, start it:**
   ```bash
   ./start_app_background.sh
   ```

3. **Wait a few seconds** for it to start, then try the icon again

4. **Check logs** if it still doesn't work:
   ```bash
   tail -20 stock_rava.log
   ```

5. **Manual test:** Open browser to http://localhost:8501 directly

---

## First Time Setup 🚀

**Setting up Stock RAVA for the first time:**

### Step 1: Install Dependencies

```bash
# Navigate to project directory
cd ~/stock-rava

# Make scripts executable
chmod +x *.sh

# Add ~/.local/bin to PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
export PATH="$HOME/.local/bin:$PATH"

# Install Python packages
pip install --upgrade pip --break-system-packages
pip install -r requirements_app.txt --break-system-packages

# Verify installation
streamlit --version
```

### Step 2: Install Desktop Shortcut

```bash
./install_desktop.sh
```

This creates the "Stock RAVA" icon in your application menu.

### Step 3: Set Up Auto-Start (Recommended)

```bash
./install_service.sh
loginctl enable-linger $USER
```

This makes the app start automatically on boot.

### Step 4: Test It

1. **Start the app:**
   ```bash
   ./start_app_background.sh
   ```

2. **Click the desktop icon** or open http://localhost:8501

3. **You should see** the Stock RAVA dashboard!

---

## Technical Overview

**For developers and administrators:**

### Application Architecture

**Stock RAVA** is a web-based Risk And Volatility Analysis Dashboard built with:
- **Framework**: Streamlit (Python web framework)
- **Main File**: `Stock_RAVA.py`
- **Port**: 8501 (default)
- **Access**: http://localhost:8501

### Key Components

1. **Main Application** (`Stock_RAVA.py`)
   - Streamlit web application
   - Provides web interface for stock analysis
   - Runs on port 8501

2. **Deployment Scripts**
   - `start_app_background.sh` - Background process (nohup)
   - `start_app_screen.sh` - Screen session (interactive)
   - `install_service.sh` - Systemd service (production)
   - `stop_app.sh` - Stop background processes
   - `status_app.sh` - Check process status

3. **Common Functions** (`app_common.sh`)
   - Shared by all scripts
   - Virtual environment detection
   - Python/Streamlit checks
   - Port checking

---

## Deployment Methods Explained

**Technical details of how Stock RAVA can be deployed:**

### Method 1: Background Script (`start_app_background.sh`)

**How it works:**
- Uses `nohup` to run process in background
- Saves PID to `stock_rava.pid` for process management
- Redirects output to `stock_rava.log`
- Process survives terminal closure
- **Process type**: Background daemon (nohup)

**Technical details:**
```bash
nohup streamlit run Stock_RAVA.py --server.headless true > stock_rava.log 2>&1 &
echo $! > stock_rava.pid
```

**Use cases:**
- Quick testing
- Single-user deployment
- Development environments
- Systems without systemd

**Limitations:**
- No auto-restart on crash
- No auto-start on boot
- Manual log management
- PID file can become stale

### Method 2: Screen Session (`start_app_screen.sh`)

**How it works:**
- Creates detached GNU Screen session named `stock_rava`
- Process runs in screen, can be attached/detached
- Interactive terminal access for debugging
- **Process type**: Foreground in detached screen session

**Technical details:**
```bash
screen -dmS stock_rava bash -c "cd '$PROJECT_ROOT' && streamlit run Stock_RAVA.py --server.headless true; exec bash"
```

**Use cases:**
- Development and debugging
- Interactive monitoring
- Need to see live output
- Testing and troubleshooting

**Limitations:**
- Session ends if screen process dies
- No auto-restart
- Requires screen to be installed
- Not suitable for production

### Method 3: Systemd User Service (`install_service.sh`)

**How it works:**
- Creates systemd user service unit file
- Service managed by systemd daemon
- Auto-starts on login (or boot with lingering)
- Auto-restarts on failure
- **Process type**: Managed systemd service

**Technical details:**
- Service file: `~/.config/systemd/user/stock-rava.service`
- Managed via `systemctl --user` commands
- Logs via `journalctl --user`
- Restart policy: `Restart=always`

**Use cases:**
- Production deployment
- Always-on servers
- Auto-start requirements
- Professional deployment

**Advantages:**
- Auto-restart on crash
- Auto-start on boot/login
- Integrated logging (journald)
- System integration
- Process monitoring

---

## Background vs Foreground Processes

**Understanding the difference and when to use each:**

### Background Processes

**What they are:**
- Run independently of terminal session
- No visible terminal output
- Continue running after terminal closes
- Managed via PID files or service managers

**How Stock RAVA uses them:**

1. **Background Script Method:**
   ```bash
   nohup streamlit run Stock_RAVA.py > log.txt 2>&1 &
   ```
   - Process runs in background
   - Output redirected to log file
   - PID saved for management
   - Can close terminal

2. **Systemd Service Method:**
   ```bash
   systemctl --user start stock-rava.service
   ```
   - Managed by systemd
   - Runs as background service
   - Auto-restart capabilities
   - Integrated with system

**Characteristics:**
- ✅ Survives terminal closure
- ✅ No interactive output
- ✅ Suitable for production
- ✅ Can run on boot
- ❌ Harder to debug (need logs)
- ❌ No interactive access

### Foreground Processes

**What they are:**
- Run in active terminal session
- Visible output in terminal
- Stop when terminal closes
- Interactive access available

**How Stock RAVA uses them:**

1. **Screen Session Method:**
   ```bash
   screen -r stock_rava
   ```
   - Process runs in screen session
   - Can attach/detach
   - See live output
   - Interactive debugging

2. **Direct Run (Development):**
   ```bash
   streamlit run Stock_RAVA.py
   ```
   - Runs in current terminal
   - See all output
   - Interactive debugging
   - Stops when terminal closes

**Characteristics:**
- ✅ Easy to debug
- ✅ See live output
- ✅ Interactive access
- ✅ Good for development
- ❌ Stops with terminal
- ❌ Not suitable for production
- ❌ Requires active session

### Process Lifecycle Comparison

| Aspect | Background (nohup) | Background (systemd) | Foreground (screen) |
|--------|-------------------|---------------------|-------------------|
| **Terminal closure** | ✅ Survives | ✅ Survives | ❌ Stops |
| **Auto-restart** | ❌ No | ✅ Yes | ❌ No |
| **Auto-start** | ❌ No | ✅ Yes | ❌ No |
| **Logging** | File-based | journald | Terminal |
| **Debugging** | View logs | View logs | Live output |
| **Production** | ⚠️ Limited | ✅ Yes | ❌ No |
| **Development** | ✅ Yes | ✅ Yes | ✅ Best |

---

## System Architecture

**Detailed technical architecture of Stock RAVA deployment:**

### Process Flow

```
User Action
    ↓
Desktop Icon Click
    ↓
xdg-open http://localhost:8501
    ↓
Browser Request
    ↓
Streamlit Server (Port 8501)
    ↓
Stock_RAVA.py Application
    ↓
Response to Browser
```

### Component Interaction

1. **Desktop Shortcut** (`stock-rava.desktop`)
   - Executes: `xdg-open http://localhost:8501`
   - Opens default browser
   - No direct process management

2. **Background Process** (nohup/systemd)
   - Runs: `streamlit run Stock_RAVA.py`
   - Listens on: `localhost:8501`
   - Serves web interface

3. **Application** (`Stock_RAVA.py`)
   - Streamlit web framework
   - Processes stock data
   - Generates visualizations
   - Serves HTML/JavaScript

### File Structure

```
stock-rava/
├── Stock_RAVA.py              # Main application
├── stock-rava-icon.png        # Desktop icon
├── stock-rava.desktop         # Desktop shortcut file
├── app_common.sh              # Shared functions
├── start_app_background.sh    # Background process script
├── start_app_screen.sh        # Screen session script
├── install_service.sh         # Systemd service installer
├── stop_app.sh                # Process stopper
├── status_app.sh              # Status checker
├── install_desktop.sh         # Desktop shortcut installer
├── stock_rava.log             # Background process logs
└── stock_rava.pid             # Process ID file
```

### Process Management

**Background Script Method:**
- PID stored in `stock_rava.pid`
- Logs in `stock_rava.log`
- Managed via `stop_app.sh` and `status_app.sh`

**Systemd Service Method:**
- Service file: `~/.config/systemd/user/stock-rava.service`
- Managed via `systemctl --user`
- Logs via `journalctl --user`

**Screen Session Method:**
- Session name: `stock_rava`
- Managed via `screen` commands
- Output visible when attached

---

## Advanced Configuration

**For developers: Customizing and extending Stock RAVA deployment:**

### Custom Streamlit Configuration

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

### Script Customization

**Modifying startup behavior:**
- Edit `app_common.sh` for shared functions
- Modify individual scripts for specific behavior
- All scripts source `app_common.sh` for consistency

---

## Troubleshooting & Debugging

**For developers: Diagnosing and fixing issues:**

### Debugging Background Processes

**Check process status:**
```bash
# Using status script
./status_app.sh

# Manual check
ps aux | grep streamlit
cat stock_rava.pid  # If using background script
```

**View logs:**
```bash
# Background script logs
tail -f stock_rava.log

# Systemd service logs
journalctl --user -u stock-rava.service -f

# Last 50 lines
journalctl --user -u stock-rava.service -n 50
```

**Check port binding:**
```bash
# See what's using port 8501
ss -tuln | grep :8501
lsof -i :8501

# Test connection
curl http://localhost:8501
```

### Common Issues

**Script exits immediately after "Using system Python":**
- Fixed in current version (uses `setup_python_env || true`)
- If still happening, check Streamlit installation:
  ```bash
  streamlit --version
  pip install streamlit --break-system-packages
  ```

**Port already in use:**
```bash
# Find and kill process
lsof -ti :8501 | xargs kill -9
# Or use stop script
./stop_app.sh
```

**Service won't start:**
```bash
# Check service status
systemctl --user status stock-rava.service -l --no-pager

# Check logs
journalctl --user -u stock-rava.service

# Verify service file
cat ~/.config/systemd/user/stock-rava.service
```

**Virtual environment not detected:**
```bash
# Check venv exists
ls -la | grep -E "venv|fintech_env|.venv"

# Manual activation test
source venv/bin/activate  # or fintech_env/bin/activate
which python
streamlit --version
```

### Development Debugging

**Run in foreground for debugging:**
```bash
# Direct run (see all output)
streamlit run Stock_RAVA.py

# Or use screen session
./start_app_screen.sh
screen -r stock_rava
```

**Enable verbose logging:**
```bash
# Streamlit debug mode
streamlit run Stock_RAVA.py --logger.level=debug

# Python debug mode
python -m streamlit run Stock_RAVA.py --logger.level=debug
```

### Performance Debugging

**Monitor resource usage:**
```bash
# While app is running
top -p $(cat stock_rava.pid)

# Or use htop
htop

# Check memory
ps aux | grep streamlit | awk '{print $4, $11}'
```

**Check for memory leaks:**
```bash
# Monitor over time
watch -n 5 'ps aux | grep streamlit'
```

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

## Virtual Environments (Optional)

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

**Access the application:**
- Open your browser and go to: **http://localhost:8501**
- The script may auto-open your browser, but you can always navigate manually

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

**Access the application:**
- Open your browser and go to: **http://localhost:8501**
- You can detach from screen and the app will keep running

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

### Option 3: Systemd User Service (Production) - **Recommended for Auto-Start**

**Best for**: Production deployment, auto-start on boot, reliability

**Install the service (auto-starts on boot):**
```bash
cd ~/stock-rava
./install_service.sh

# Enable lingering (so it runs even when not logged in)
loginctl enable-linger $USER
```

**Access the application:**
- Open your browser and go to: **http://localhost:8501**
- Service runs automatically after installation (if you chose to start it)
- **Will start automatically on every boot** once enabled

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

**Enable lingering (so service runs on boot even when not logged in):**
```bash
# This allows the service to start on system boot, not just on login
loginctl enable-linger $USER

# To disable lingering (service only starts on login)
loginctl disable-linger $USER
```

**Important:** Without lingering, the service only starts when you log in. With lingering enabled, it starts when the system boots, even if no one is logged in.

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

### How do I access the application?

**The application is a web interface accessed through your browser:**

1. **Make sure the app is running:**
   ```bash
   ./status_app.sh
   ```

2. **Open your web browser** (Firefox, Chrome, Chromium, etc.)

3. **Navigate to**: `http://localhost:8501`

4. **If it doesn't load:**
   - Check if the app is actually running: `./status_app.sh`
   - Check if port 8501 is in use: `ss -tuln | grep :8501`
   - Check logs: `tail -f stock_rava.log` or `journalctl --user -u stock-rava.service -f`
   - Try restarting: `./stop_app.sh` then `./start_app_background.sh`

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

**Script exits immediately after "Using system Python":**

If the script stops right after showing "✓ Using system Python (system-wide installation)" without starting the app, this was a known issue that has been fixed. If you encounter this:

1. Make sure you have the latest version of `start_app_background.sh`
2. The script should continue and show "✓ Streamlit found" - if it doesn't, check your Streamlit installation:
   ```bash
   streamlit --version
   ```
3. If Streamlit is not found, install it:
   ```bash
   pip install streamlit --break-system-packages
   ```

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
