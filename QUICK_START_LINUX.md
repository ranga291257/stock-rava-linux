# Quick Start Guide - Stock RAVA (Linux)

**Stock RAVA** = Risk And Volatility Analysis Dashboard

## 🚀 Quick Start (3 Steps)

### 1. Setup Virtual Environment (Recommended)

**Create `fintech_env` to keep system Python clean:**
```bash
python3 -m venv fintech_env
source fintech_env/bin/activate
```

### 2. Install Dependencies
```bash
# With venv activated
pip install --upgrade pip
pip install -r requirements_app.txt
```

> **Note**: Scripts auto-detect `fintech_env`, `venv`, or `.venv` if present.

Or install manually:
```bash
pip3 install streamlit pandas numpy matplotlib yfinance ffn quantstats
```

### 2. Run the Application

**Option A: Background Script (Recommended)**
```bash
./start_app_background.sh
```

**Option B: Screen Session (Development)**
```bash
./start_app_screen.sh
```

**Option C: Manual Start**
```bash
streamlit run Stock_RAVA.py
```

### 3. Access the Dashboard
- Open your browser: http://localhost:8501
- Enter a ticker (e.g., `AAPL`, `^GSPC`, `MSFT`)
- Click "🚀 Run Analysis"
- View results!

## 📋 Managing the App

### Check Status
```bash
./status_app.sh
```

### Stop the App
```bash
./stop_app.sh
```

### View Logs
```bash
tail -f stock_rava.log
```

### Reattach to Screen Session
```bash
screen -r stock_rava
# Press Ctrl+A then D to detach
```

## 🖥️ Production Deployment (Systemd Service)

### Install as Service
```bash
./install_service.sh
```

The service will:
- Start automatically on login
- Restart if it crashes
- Run in background

### Service Commands
```bash
# Start
systemctl --user start stock-rava.service

# Stop
systemctl --user stop stock-rava.service

# Status
systemctl --user status stock-rava.service

# View logs
journalctl --user -u stock-rava.service -f

# Disable auto-start
systemctl --user disable stock-rava.service
```

### Uninstall Service
```bash
./uninstall_service.sh
```

## 📝 Recent Updates

- **Linux Deployment**: Full Linux/Ubuntu 24.x support
- **Background Scripts**: Easy background execution
- **Systemd Service**: Production-ready deployment
- **Screen Sessions**: Development-friendly option

## 🔧 Technical Stack

- **Framework**: Streamlit (web interface)
- **Data**: Yahoo Finance (yfinance)
- **Analysis**: ffn + quantstats libraries
- **Visualization**: Matplotlib
- **Processing**: Pandas + NumPy

## ⚡ Performance Tips

- First run: 10-30 seconds (downloads data)
- Subsequent runs: 2-5 seconds (cached)
- Caching: 1 hour TTL for ticker data

## 🆚 Deployment Options Comparison

| Method | Use Case | Auto-Start | Restart on Crash |
|--------|----------|------------|-------------------|
| **Background Script** | Quick start | ❌ | ❌ |
| **Screen Session** | Development | ❌ | ❌ |
| **Systemd Service** | Production | ✅ | ✅ |

## 🐧 Ubuntu 24.x Specific Notes

- Uses systemd for service management
- Compatible with Ubuntu 24.04 LTS
- Tested with Python 3.12 (default on Ubuntu 24.04)
- Uses `xdg-open` for browser auto-launch

