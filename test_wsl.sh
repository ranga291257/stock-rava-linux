#!/bin/bash
# Quick test script for Stock RAVA Linux deployment in WSL
# Usage: ./test_wsl.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
cd "$PROJECT_ROOT"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=== Testing Stock RAVA in WSL ===${NC}"
echo ""

# Check Python
echo -e "${CYAN}1. Checking Python...${NC}"
if command -v python3 >/dev/null 2>&1; then
    PYTHON_VERSION=$(python3 --version 2>&1)
    echo -e "${GREEN}✓ $PYTHON_VERSION${NC}"
else
    echo -e "${RED}✗ Python 3 not found${NC}"
    echo "   Install with: sudo apt-get install python3 python3-pip"
    exit 1
fi

# Check pip
echo -e "${CYAN}2. Checking pip...${NC}"
if command -v pip3 >/dev/null 2>&1; then
    echo -e "${GREEN}✓ pip3 found${NC}"
else
    echo -e "${YELLOW}⚠ pip3 not found${NC}"
    echo "   Install with: sudo apt-get install python3-pip"
fi

# Check Streamlit
echo -e "${CYAN}3. Checking Streamlit...${NC}"
if command -v streamlit >/dev/null 2>&1; then
    STREAMLIT_VERSION=$(streamlit --version 2>&1 | head -n 1)
    echo -e "${GREEN}✓ $STREAMLIT_VERSION${NC}"
else
    echo -e "${YELLOW}⚠ Streamlit not found${NC}"
    echo "   Install with: pip3 install streamlit"
    echo "   Or install all: pip3 install -r requirements_app.txt"
fi

# Check project structure
echo -e "${CYAN}4. Checking project structure...${NC}"
if [ -f "Stock_RAVA.py" ]; then
    echo -e "${GREEN}✓ Stock_RAVA.py found${NC}"
else
    echo -e "${RED}✗ Stock_RAVA.py not found${NC}"
    echo "   Make sure you're in the project root directory"
    exit 1
fi

if [ -f "requirements_app.txt" ]; then
    echo -e "${GREEN}✓ requirements_app.txt found${NC}"
else
    echo -e "${YELLOW}⚠ requirements_app.txt not found${NC}"
fi

# Check Linux scripts
echo -e "${CYAN}5. Checking Linux deployment scripts...${NC}"
SCRIPT_COUNT=0
for script in start_app_background.sh start_app_screen.sh stop_app.sh status_app.sh install_service.sh uninstall_service.sh; do
    if [ -f "$script" ]; then
        chmod +x "$script" 2>/dev/null || true
        SCRIPT_COUNT=$((SCRIPT_COUNT + 1))
        echo -e "${GREEN}✓ $script${NC}"
    else
        echo -e "${RED}✗ $script not found${NC}"
    fi
done

if [ $SCRIPT_COUNT -eq 6 ]; then
    echo -e "${GREEN}✓ All scripts found and made executable${NC}"
else
    echo -e "${YELLOW}⚠ Some scripts missing ($SCRIPT_COUNT/6 found)${NC}"
fi

# Check port 8501
echo -e "${CYAN}6. Checking port 8501...${NC}"
PORT_IN_USE=false

if command -v ss >/dev/null 2>&1; then
    if ss -tuln 2>/dev/null | grep -q ':8501 '; then
        PORT_IN_USE=true
    fi
elif command -v netstat >/dev/null 2>&1; then
    if netstat -tuln 2>/dev/null | grep -q ':8501 '; then
        PORT_IN_USE=true
    fi
fi

if [ "$PORT_IN_USE" = true ]; then
    echo -e "${YELLOW}⚠ Port 8501 is in use${NC}"
    echo "   Run './stop_app.sh' to stop existing instance"
else
    echo -e "${GREEN}✓ Port 8501 is available${NC}"
fi

# Check WSL environment
echo -e "${CYAN}7. Checking WSL environment...${NC}"
if [ -f /proc/version ] && grep -q -i microsoft /proc/version; then
    echo -e "${GREEN}✓ Running in WSL${NC}"
    
    # Check if systemd is available
    if systemctl --user list-units >/dev/null 2>&1; then
        echo -e "${GREEN}✓ systemd user services available${NC}"
    else
        echo -e "${YELLOW}⚠ systemd not available (WSL1 or old WSL2)${NC}"
        echo "   Use background scripts or screen sessions instead"
    fi
else
    echo -e "${YELLOW}⚠ Not running in WSL (or WSL detection failed)${NC}"
    echo "   This is fine if testing on real Linux"
fi

# Check file permissions
echo -e "${CYAN}8. Checking file permissions...${NC}"
if [ -d "/mnt" ]; then
    # We're likely accessing Windows files
    CURRENT_PATH=$(pwd)
    if [[ "$CURRENT_PATH" == /mnt/* ]]; then
        echo -e "${YELLOW}⚠ Accessing Windows filesystem (slower I/O)${NC}"
        echo "   Consider copying to ~/boom_bust for better performance"
    else
        echo -e "${GREEN}✓ Using native Linux filesystem${NC}"
    fi
fi

# Check for virtual environment
echo -e "${CYAN}9. Checking for virtual environment...${NC}"
if [ -n "$VIRTUAL_ENV" ]; then
    echo -e "${GREEN}✓ Virtual environment active: $VIRTUAL_ENV${NC}"
elif [ -d "$PROJECT_ROOT/fintech_env" ]; then
    echo -e "${GREEN}✓ Found fintech_env${NC}"
    echo "   Activate with: source fintech_env/bin/activate"
elif [ -d "$PROJECT_ROOT/venv" ]; then
    echo -e "${GREEN}✓ Found venv directory (not activated)${NC}"
    echo "   Activate with: source venv/bin/activate"
elif [ -d "$PROJECT_ROOT/.venv" ]; then
    echo -e "${GREEN}✓ Found .venv directory (not activated)${NC}"
    echo "   Activate with: source .venv/bin/activate"
else
    echo -e "${GREEN}✓ Using system Python (system-wide installation)${NC}"
    echo "   Virtual environment optional - fine for dedicated small Linux boxes"
fi

echo ""
echo -e "${CYAN}=== Test Summary ===${NC}"
echo ""
echo -e "${GREEN}Ready to test! Next steps:${NC}"
echo ""
echo "1. Start the app:"
echo "   ${CYAN}./start_app_background.sh${NC}"
echo ""
echo "2. Check status:"
echo "   ${CYAN}./status_app.sh${NC}"
echo ""
echo "3. Open in Windows browser:"
echo "   ${CYAN}http://localhost:8501${NC}"
echo ""
echo "4. Stop the app:"
echo "   ${CYAN}./stop_app.sh${NC}"
echo ""
echo -e "${GREEN}For detailed WSL testing guide, see: README_LINUX.md (Testing in WSL section)${NC}"

