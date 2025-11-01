# Stock RAVA - Linux Deployment

Linux deployment scripts and documentation for **Stock RAVA** (Risk And Volatility Analysis Dashboard).

## Quick Start

See [QUICK_START_LINUX.md](QUICK_START_LINUX.md) for a quick start guide.

## Documentation

- **[README_LINUX.md](README_LINUX.md)** - Complete Linux deployment guide
- **[QUICK_START_LINUX.md](QUICK_START_LINUX.md)** - Quick start (3 steps)
- **[SETUP_VENV.md](SETUP_VENV.md)** - Virtual environment setup guide
- **[TEST_WSL.md](TEST_WSL.md)** - WSL testing guide
- **[README_WSL_QUICKSTART.md](README_WSL_QUICKSTART.md)** - Quick WSL test guide

## Features

- ✅ Background script deployment
- ✅ GNU Screen session support
- ✅ Systemd service integration
- ✅ Virtual environment auto-detection
- ✅ WSL/WSL2 compatible
- ✅ Ubuntu 24.x tested

## Installation

```bash
# 1. Create virtual environment
python3 -m venv fintech_env
source fintech_env/bin/activate

# 2. Install dependencies
pip install --upgrade pip
pip install -r requirements_app.txt

# 3. Start the app
./start_app_background.sh
```

## Requirements

- Python 3.8+
- Linux (Ubuntu 24.x recommended)
- Virtual environment (recommended: fintech_env)

## License

See parent project for license information.

