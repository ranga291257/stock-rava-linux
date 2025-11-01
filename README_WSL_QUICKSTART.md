# Quick Start - Testing in WSL

## 30-Second Quick Test

```bash
# 1. Open WSL terminal
wsl

# 2. Navigate to project directory (linux subdirectory)
cd /mnt/d/poc/Fintec/boom_bust/linux  # adjust path as needed

# 3. (Recommended) Create virtual environment
python3 -m venv fintech_env
source fintech_env/bin/activate
pip install --upgrade pip
pip install -r requirements_app.txt

# 4. Run test script
./test_wsl.sh

# 5. Start the app (auto-detects fintech_env)
./start_app_background.sh

# 6. Open in Windows browser
# http://localhost:8501
```

> **Note**: Scripts automatically detect and use `fintech_env` if present!

That's it! The app should be running and accessible from your Windows browser.

## Detailed Testing

For complete instructions, see `TEST_WSL.md`

