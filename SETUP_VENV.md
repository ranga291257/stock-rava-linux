# Setting Up Virtual Environment for Stock RAVA

## Why Use a Virtual Environment?

**Best Practice**: Always use a virtual environment for finance/project work to:
- ✅ **Isolate dependencies** - Keep project packages separate from system Python
- ✅ **Avoid conflicts** - Different projects may need different package versions
- ✅ **Keep system clean** - Protect Ubuntu's native Python 3.12.7 from modifications
- ✅ **Reproducibility** - Same environment across development/production
- ✅ **Easy cleanup** - Delete venv folder to remove all dependencies

## Recommended: Create `fintech_env`

For finance-related projects, creating a dedicated `fintech_env` is ideal:

```bash
# Navigate to project directory (linux subdirectory)
cd /mnt/d/poc/Fintec/boom_bust/linux  # or your path

# Create virtual environment named 'fintech_env'
python3 -m venv fintech_env

# Activate the virtual environment
source fintech_env/bin/activate

# Verify you're using venv Python
which python
# Should show: /path/to/boom_bust/fintech_env/bin/python

# Upgrade pip (best practice)
pip install --upgrade pip

# Install project dependencies
pip install -r requirements_app.txt
```

## Project-Specific venv (Alternative)

If you prefer a project-specific name:

```bash
# Create venv in project directory
python3 -m venv venv

# Or hidden version
python3 -m venv .venv
```

## Using fintech_env

### Activation

**Linux/WSL:**
```bash
cd /mnt/d/poc/Fintec/boom_bust/linux
source fintech_env/bin/activate
```

**In scripts:**
The Linux deployment scripts automatically detect and use `fintech_env`, `venv`, or `.venv` if present.

### Deactivation

```bash
deactivate
```

## Virtual Environment Detection

The Linux scripts automatically detect and use virtual environments in this order:

1. **Currently active venv** (`$VIRTUAL_ENV` environment variable)
2. **`fintech_env/`** in project root
3. **`venv/`** in project root
4. **`.venv/`** in project root
5. **System Python** (fallback)

### Verify Auto-Detection

```bash
# Run the test script
./test_wsl.sh

# Check step 9 - it will show if venv is detected
```

## Running Stock RAVA with fintech_env

Once `fintech_env` is created and activated:

```bash
# Option 1: Background script (auto-detects venv)
./start_app_background.sh

# Option 2: Screen session (auto-detects venv)
./start_app_screen.sh

# Option 3: Systemd service (auto-configures venv)
./install_service.sh
```

All scripts will automatically use `fintech_env` if present!

## Managing Dependencies

### Update requirements file

```bash
# Activate venv first
source fintech_env/bin/activate

# Generate requirements from current environment
pip freeze > requirements_app.txt

# Or add a new package
pip install some-package
pip freeze > requirements_app.txt
```

### Reinstall on another machine

```bash
# Create venv
python3 -m venv fintech_env

# Activate
source fintech_env/bin/activate

# Install all dependencies
pip install -r requirements_app.txt
```

## Best Practices

### 1. Always activate before installing packages

```bash
# ❌ Bad - installs to system Python
pip install streamlit

# ✅ Good - installs to venv
source fintech_env/bin/activate
pip install streamlit
```

### 2. Check which Python you're using

```bash
# Should show venv path when active
which python
which pip
```

### 3. Keep requirements.txt updated

```bash
source fintech_env/bin/activate
pip install <new-package>
pip freeze > requirements_app.txt
```

### 4. Systemd Service with venv

When you run `./install_service.sh`:
- It automatically detects `fintech_env` or `venv`
- Configures the service to use the venv Python
- Sets PATH to include venv binaries

## .gitignore

The virtual environment is already ignored:
```
venv/
.venv/
fintech_env/
```

## Troubleshooting

### Scripts not detecting venv

**Check venv exists:**
```bash
ls -la | grep fintech_env
```

**Ensure scripts are executable:**
```bash
chmod +x *.sh
```

**Manual activation:**
```bash
source fintech_env/bin/activate
./start_app_background.sh
```

### Systemd service not using venv

**Reinstall service after creating venv:**
```bash
./uninstall_service.sh
./install_service.sh
```

The install script will detect and configure the venv automatically.

### Venv Python version mismatch

**Create venv with specific Python version:**
```bash
python3.12 -m venv fintech_env
# Or
python3.11 -m venv fintech_env
```

## Summary

**Recommended Setup:**
1. Create `fintech_env` in the linux directory
2. Install dependencies with venv activated
3. All scripts auto-detect and use venv
4. System Python 3.12.7 remains clean

**Benefits:**
- System Python stays pristine
- Easy dependency management
- Project isolation
- Reproducible environments


