#!/bin/bash
# Bash script to run Stock RAVA in background on Linux
# Usage: ./start_app_background.sh

set -e  # Exit on error

# Get script directory (this is now the project root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
cd "$PROJECT_ROOT"

# PID and log file locations
PID_FILE="$SCRIPT_DIR/stock_rava.pid"
LOG_FILE="$SCRIPT_DIR/stock_rava.log"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if already running
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠ App is already running (PID: $OLD_PID)${NC}"
        echo "To stop it, run: ./stop_app.sh"
        exit 1
    else
        # Stale PID file
        rm -f "$PID_FILE"
    fi
fi

# Check Python
if ! command_exists python3; then
    echo -e "${RED}✗ Python 3 not found. Please install Python 3.8 or higher.${NC}"
    exit 1
fi

PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}' | cut -d. -f1,2)
echo -e "${GREEN}✓ Python ${PYTHON_VERSION} found${NC}"

# Auto-detect virtual environment (checks fintech_env first for finance projects)
if [ -n "$VIRTUAL_ENV" ]; then
    echo -e "${GREEN}✓ Virtual environment detected: $VIRTUAL_ENV${NC}"
    PYTHON_CMD="$VIRTUAL_ENV/bin/python"
    PIP_CMD="$VIRTUAL_ENV/bin/pip"
    STREAMLIT_CMD="$VIRTUAL_ENV/bin/streamlit"
elif [ -f "$PROJECT_ROOT/fintech_env/bin/activate" ]; then
    echo -e "${GREEN}✓ Found fintech_env, activating...${NC}"
    echo -e "${CYAN}  (Recommended: keeps system Python 3.12.7 clean)${NC}"
    source "$PROJECT_ROOT/fintech_env/bin/activate"
    PYTHON_CMD="python"
    PIP_CMD="pip"
    STREAMLIT_CMD="streamlit"
elif [ -f "$PROJECT_ROOT/venv/bin/activate" ]; then
    echo -e "${GREEN}✓ Found venv in project, activating...${NC}"
    source "$PROJECT_ROOT/venv/bin/activate"
    PYTHON_CMD="python"
    PIP_CMD="pip"
    STREAMLIT_CMD="streamlit"
elif [ -f "$PROJECT_ROOT/.venv/bin/activate" ]; then
    echo -e "${GREEN}✓ Found .venv in project, activating...${NC}"
    source "$PROJECT_ROOT/.venv/bin/activate"
    PYTHON_CMD="python"
    PIP_CMD="pip"
    STREAMLIT_CMD="streamlit"
else
    echo -e "${YELLOW}⚠ No virtual environment found - using system Python${NC}"
    echo -e "${YELLOW}  Recommendation: Create fintech_env to keep system Python clean${NC}"
    echo -e "${YELLOW}  Run: python3 -m venv fintech_env${NC}"
    PYTHON_CMD="python3"
    PIP_CMD="pip3"
    STREAMLIT_CMD="streamlit"
fi

# Check Streamlit
if [ "$STREAMLIT_CMD" = "streamlit" ]; then
    # Using system streamlit, check if it exists
    if ! command_exists streamlit; then
        echo -e "${YELLOW}✗ Streamlit not found. Installing...${NC}"
        $PIP_CMD install streamlit
        if [ $? -ne 0 ]; then
            echo -e "${RED}✗ Failed to install Streamlit. Please install manually: $PIP_CMD install streamlit${NC}"
            exit 1
        fi
    fi
elif [ -f "$STREAMLIT_CMD" ]; then
    # Using venv streamlit, verify it exists
    if [ ! -x "$STREAMLIT_CMD" ]; then
        echo -e "${RED}✗ Streamlit found but not executable: $STREAMLIT_CMD${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ Streamlit found${NC}"

# Ubuntu 24.x specific checks
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" == "ubuntu" ]] && [[ "$VERSION_ID" == "24.04"* ]]; then
        echo -e "${GREEN}✓ Ubuntu 24.04 detected${NC}"
        # Check for systemd support (WSL2 with systemd or native Ubuntu)
        if systemctl --user list-units >/dev/null 2>&1; then
            echo -e "${GREEN}✓ systemd user services available${NC}"
        fi
    fi
fi

# Check if port 8501 is in use
if command_exists ss; then
    if ss -tuln 2>/dev/null | grep -q ':8501 '; then
        echo -e "${YELLOW}⚠ Port 8501 is already in use${NC}"
        echo "Stopping existing processes..."
        pkill -f "streamlit.*Stock_RAVA" 2>/dev/null || true
        sleep 2
    fi
elif command_exists netstat; then
    if netstat -tuln 2>/dev/null | grep -q ':8501 '; then
        echo -e "${YELLOW}⚠ Port 8501 is already in use${NC}"
        echo "Stopping existing processes..."
        pkill -f "streamlit.*Stock_RAVA" 2>/dev/null || true
        sleep 2
    fi
fi

# Start Streamlit in background
echo -e "\n${CYAN}Starting Stock RAVA in background...${NC}"
echo -e "${CYAN}App will be available at: http://localhost:8501${NC}"

# Use nohup to run in background
nohup $STREAMLIT_CMD run Stock_RAVA.py --server.headless true > "$LOG_FILE" 2>&1 &
APP_PID=$!

# Save PID
echo $APP_PID > "$PID_FILE"

# Wait a moment for server to start
sleep 3

# Check if process is still running
if ps -p "$APP_PID" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Stock RAVA started (PID: $APP_PID)${NC}"
    echo -e "\n${YELLOW}To stop the app, run: ./stop_app.sh${NC}"
    echo -e "${YELLOW}Or manually stop with: kill $APP_PID${NC}"
    
    # Try to open browser (if xdg-open is available)
    if command_exists xdg-open; then
        echo -e "\n${GREEN}✓ App is running! Opening browser...${NC}"
        xdg-open "http://localhost:8501" 2>/dev/null || true
    else
        echo -e "\n${GREEN}✓ App is running!${NC}"
        echo "Open http://localhost:8501 in your browser"
    fi
    
    echo -e "\n${CYAN}Logs are being written to: $LOG_FILE${NC}"
    echo -e "${CYAN}View logs with: tail -f $LOG_FILE${NC}"
else
    echo -e "${RED}✗ Failed to start Stock RAVA${NC}"
    echo "Check logs: cat $LOG_FILE"
    rm -f "$PID_FILE"
    exit 1
fi

