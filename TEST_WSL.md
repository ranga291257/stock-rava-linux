# Testing Stock RAVA Linux Deployment in WSL

This guide helps you test the Linux deployment scripts using Windows Subsystem for Linux (WSL) on Windows 11.

## Prerequisites

### 1. Install WSL (if not already installed)

**Windows 11:**
```powershell
# Install WSL with default Ubuntu distribution
wsl --install

# Or install specific Ubuntu version
wsl --install -d Ubuntu-24.04
```

**Verify WSL installation:**
```powershell
wsl --list --verbose
```

### 2. Access Your Project in WSL

The Windows file system is accessible from WSL at `/mnt/c/`, `/mnt/d/`, etc.

**Navigate to project:**
```bash
# If your project is at D:\poc\Fintec\boom_bust\linux
cd /mnt/d/poc/Fintec/boom_bust/linux

# Verify you're in the right directory
ls -la
```

**Or clone/share the project within WSL:**
```bash
# Create a link or copy to WSL home directory
cp -r /mnt/d/poc/Fintec/boom_bust/linux ~/boom_bust-linux
cd ~/boom_bust-linux
```

## Quick Test Steps

### Step 1: Install Dependencies in WSL

**Recommended: Use Virtual Environment (fintech_env)**

```bash
# Update package list
sudo apt-get update

# Install Python (if not already installed)
sudo apt-get install -y python3 python3-pip python3-venv

# Verify Python version (should be 3.8+)
python3 --version

# Create virtual environment (recommended: keeps system Python clean)
cd /mnt/d/poc/Fintec/boom_bust/linux  # or your path
python3 -m venv fintech_env

# Activate virtual environment
source fintech_env/bin/activate

# Upgrade pip (best practice)
pip install --upgrade pip

# Install Python dependencies
pip install -r requirements_app.txt
```

**Without Virtual Environment (Not Recommended):**
```bash
# Only if you must use system Python
pip3 install -r requirements_app.txt
# ⚠️ This modifies system Python packages
```

### Step 2: Make Scripts Executable

```bash
# Navigate to project directory (linux subdirectory)
cd /mnt/d/poc/Fintec/boom_bust/linux  # or your path

# Make all scripts executable
chmod +x *.sh

# Verify
ls -la *.sh
```

### Step 3: Test Background Script

```bash
# Start the app in background
./start_app_background.sh

# Wait a few seconds, then check status
./status_app.sh
```

# Check if port 8501 is listening
ss -tuln | grep :8501
# Or (if netstat is installed)
netstat -tuln | grep :8501
```

### Step 4: Test from Windows Browser

Open in Windows browser:
- http://localhost:8501

**Note**: WSL2 automatically forwards ports to Windows, so `localhost:8501` in Windows browser will work!

### Step 5: Stop the App

```bash
# Stop the background app
./stop_app.sh

# Verify it's stopped
./status_app.sh
```

## Testing Screen Session

```bash
# Test screen session start
./start_app_screen.sh
```

# You'll be attached to the session
# Press Ctrl+A then D to detach

# Reattach later
screen -r stock_rava

# Kill screen session when done
screen -X -S stock_rava quit
```

## Testing Systemd Service (Advanced)

**Note**: WSL1 doesn't support systemd. WSL2 with systemd support (Windows 11 22H2+) can use systemd.

### Check if systemd is available:
```bash
systemctl --user list-units
```

If this works, you can test the systemd service:

```bash
# Install the service
./install_service.sh

# Check status
systemctl --user status stock-rava.service

# View logs
journalctl --user -u stock-rava.service -f

# Stop and uninstall
./uninstall_service.sh
```

**If systemd is not available in WSL**, use the background scripts or screen sessions instead.

## Troubleshooting WSL Testing

### Issue: Can't access Windows files

**Solution**: Use the `/mnt/` mount points:
```bash
cd /mnt/d/poc/Fintec/boom_bust/linux
```

### Issue: Scripts not executable

**Solution**: 
```bash
chmod +x *.sh
```

### Issue: Port 8501 not accessible from Windows

**For WSL2**: Ports should auto-forward. If not:
```powershell
# Check WSL2 port forwarding
netsh interface portproxy show all
```

**For WSL1**: You may need to manually forward:
```powershell
netsh interface portproxy add v4tov4 listenport=8501 listenaddress=0.0.0.0 connectport=8501 connectaddress=<WSL_IP>
```

### Issue: Browser won't open from WSL

**Solution**: WSL can't directly open Windows browser, but you can:
1. Manually open http://localhost:8501 in Windows browser
2. Or create a test script that prints the URL

### Issue: File permissions (Windows files in WSL)

**Solution**: 
```bash
# Files from Windows may have different permissions
# This is normal and usually doesn't affect execution
# If needed, you can copy to WSL home:
cp -r /mnt/d/poc/Fintec/boom_bust/linux ~/boom_bust-linux-test
cd ~/boom_bust-linux-test
```

## Quick Test Script

The test script is already available as `test_wsl.sh`:

```bash
#!/bin/bash
echo "=== Testing Stock RAVA in WSL ==="

# Check Python
echo "1. Checking Python..."
python3 --version || { echo "❌ Python not found"; exit 1; }
echo "✅ Python OK"

# Check Streamlit
echo "2. Checking Streamlit..."
streamlit --version || { echo "❌ Streamlit not found. Run: pip3 install streamlit"; exit 1; }
echo "✅ Streamlit OK"

# Check scripts
echo "3. Checking scripts..."
for script in start_app_background.sh stop_app.sh status_app.sh; do
    if [ -f "$script" ]; then
        chmod +x "$script"
        echo "✅ $script OK"
    else
        echo "❌ $script not found"
    fi
done

# Check port
echo "4. Checking port 8501..."
if ss -tuln 2>/dev/null | grep -q ':8501 ' || netstat -tuln 2>/dev/null | grep -q ':8501 '; then
    echo "⚠️  Port 8501 is in use"
else
    echo "✅ Port 8501 is available"
fi

echo ""
echo "=== Test Complete ==="
echo "Run: ./start_app_background.sh"
echo "Then open: http://localhost:8501 in Windows browser"
```

Run it:
```bash
chmod +x test_wsl.sh
./test_wsl.sh
```

## Expected Results

✅ **Success indicators:**
- Scripts are executable
- App starts and listens on port 8501
- Status script shows app running
- Can access from Windows browser at http://localhost:8501
- Stop script cleanly terminates the app

❌ **Common issues:**
- Permission errors → Run `chmod +x *.sh`
- Port in use → Run `./stop_app.sh` first
- Python/Streamlit not found → Install dependencies
- Can't access from browser → Check WSL port forwarding

## Next Steps After Testing

Once testing is successful in WSL:
1. The same scripts will work on a real Linux server
2. Deploy to Ubuntu 24.x server using the same process
3. Use systemd service for production deployment

## Performance Notes

- WSL2 is recommended over WSL1 for better performance
- File I/O in `/mnt/` (Windows drives) is slower than native Linux
- For better performance in testing, copy project to WSL home: `~/boom_bust`
- Real Linux server will perform better than WSL

