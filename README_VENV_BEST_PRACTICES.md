# Virtual Environment Best Practices for Finance Projects

## Quick Answer

**YES - Always use a virtual environment!**

For finance-related projects like Stock RAVA, using `fintech_env` is highly recommended to:
- Keep Ubuntu's native Python 3.12.7 clean and unmodified
- Isolate finance-specific dependencies
- Prevent conflicts with system packages
- Enable easy project recreation

## Why fintech_env?

### Problem Without Virtual Environment

**System Python (Ubuntu 3.12.7):**
```bash
# Installing packages directly pollutes system Python
pip3 install streamlit pandas numpy yfinance
# Now system Python has these packages globally
# Other projects or system tools might conflict
```

### Solution With fintech_env

**Isolated Environment:**
```bash
# Create isolated environment
python3 -m venv fintech_env

# All packages go here, not system Python
source fintech_env/bin/activate
pip install streamlit pandas numpy yfinance
# System Python 3.12.7 remains pristine!
```

## Setup Guide

### Step 1: Create fintech_env

```bash
cd /mnt/d/poc/Fintec/boom_bust
python3 -m venv fintech_env
```

### Step 2: Activate

```bash
source fintech_env/bin/activate

# Verify - should show fintech_env path
which python
# Output: /mnt/d/poc/Fintec/boom_bust/fintech_env/bin/python
```

### Step 3: Install Dependencies

```bash
# Upgrade pip first
pip install --upgrade pip

# Install project dependencies
pip install -r requirements_app.txt
```

### Step 4: Use Stock RAVA

All scripts automatically detect `fintech_env`:

```bash
# Background script auto-detects fintech_env
./linux/start_app_background.sh

# Screen session auto-detects fintech_env
./linux/start_app_screen.sh

# Systemd service auto-configures fintech_env
./linux/install_service.sh
```

## Benefits for Finance Projects

### 1. Dependency Isolation

**Scenario**: You have multiple finance projects:
- Stock RAVA (needs yfinance, ffn, quantstats)
- Another project (needs different versions)

**Without venv**: Version conflicts, system Python pollution

**With fintech_env**: Each project has its own isolated environment

### 2. System Python Protection

**Ubuntu 24.04's Python 3.12.7** is used by:
- System tools and scripts
- Package managers
- Other applications

**Keeping it clean** ensures system stability.

### 3. Easy Cleanup

```bash
# Remove all dependencies instantly
rm -rf fintech_env

# Recreate fresh environment
python3 -m venv fintech_env
source fintech_env/bin/activate
pip install -r requirements_app.txt
```

### 4. Reproducibility

```bash
# On development machine
pip freeze > requirements_app.txt

# On production server
python3 -m venv fintech_env
source fintech_env/bin/activate
pip install -r requirements_app.txt
# Exact same environment!
```

## Script Auto-Detection Order

The deployment scripts check for venvs in this order:

1. **Currently active** (`$VIRTUAL_ENV`)
2. **`fintech_env/`** ← Recommended for finance projects
3. **`venv/`**
4. **`.venv/`**
5. **System Python** (fallback, shows warning)

## Example Workflow

```bash
# 1. Create environment once
cd /mnt/d/poc/Fintec/boom_bust
python3 -m venv fintech_env

# 2. Activate and install
source fintech_env/bin/activate
pip install -r requirements_app.txt

# 3. Run Stock RAVA (venv auto-detected)
./linux/start_app_background.sh

# Output will show:
# ✓ Found fintech_env, activating...
#   (Recommended: keeps system Python 3.12.7 clean)
```

## Systemd Service with fintech_env

When installing as a service:

```bash
# Create fintech_env first
python3 -m venv fintech_env
source fintech_env/bin/activate
pip install -r requirements_app.txt

# Install service (auto-detects fintech_env)
./linux/install_service.sh

# Output:
# ✓ Using fintech_env Python: /path/to/fintech_env/bin/python
#   (Recommended: keeps system Python clean)
```

The service will use `fintech_env` automatically!

## Multiple Projects Pattern

For multiple finance projects:

```
~/finance-projects/
├── stock-rava/
│   └── fintech_env/  ← Stock RAVA dependencies
├── portfolio-analyzer/
│   └── fintech_env/  ← Different dependencies
└── market-tracker/
    └── fintech_env/  ← Yet different dependencies
```

Each project has isolated dependencies!

## When to Skip Virtual Environment

**Only skip venv if:**
- Temporary/testing on a disposable machine
- Using Docker (container is already isolated)
- Single-purpose machine dedicated to this project

**Otherwise, always use venv!**

## Troubleshooting

### Scripts not detecting fintech_env

```bash
# Verify it exists
ls -la fintech_env/bin/python

# Check script is in project root
pwd
# Should be: /path/to/boom_bust

# Manually activate and run
source fintech_env/bin/activate
./linux/start_app_background.sh
```

### Systemd service not using fintech_env

```bash
# Reinstall service after creating venv
./linux/uninstall_service.sh
./linux/install_service.sh
```

## Summary

✅ **Use `fintech_env`** to keep system Python clean
✅ **All scripts auto-detect** virtual environments
✅ **Protect Ubuntu 3.12.7** from modifications
✅ **Isolate dependencies** for finance projects
✅ **Easy to recreate** or remove

**Recommended Command:**
```bash
python3 -m venv fintech_env && \
source fintech_env/bin/activate && \
pip install -r requirements_app.txt
```

This is the best practice for finance projects on Linux/Ubuntu!


