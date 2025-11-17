#!/bin/bash
# Common functions and configuration for Stock RAVA scripts
# Source this file in other scripts: source "$(dirname "$0")/app_common.sh"

# Get script directory (project root)
if [ -z "$PROJECT_ROOT" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]:-$0}")" && pwd)"
    PROJECT_ROOT="$SCRIPT_DIR"
    cd "$PROJECT_ROOT"
fi

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# PID and log file locations
PID_FILE="$PROJECT_ROOT/stock_rava.pid"
LOG_FILE="$PROJECT_ROOT/stock_rava.log"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect and setup virtual environment
# Sets: PYTHON_CMD, PIP_CMD, STREAMLIT_CMD
# Returns: 0 if venv found, 1 if using system Python
setup_python_env() {
    if [ -n "$VIRTUAL_ENV" ]; then
        echo -e "${GREEN}✓ Virtual environment detected: $VIRTUAL_ENV${NC}"
        PYTHON_CMD="$VIRTUAL_ENV/bin/python"
        PIP_CMD="$VIRTUAL_ENV/bin/pip"
        STREAMLIT_CMD="$VIRTUAL_ENV/bin/streamlit"
        return 0
    elif [ -f "$PROJECT_ROOT/fintech_env/bin/activate" ]; then
        echo -e "${GREEN}✓ Found fintech_env, activating...${NC}"
        source "$PROJECT_ROOT/fintech_env/bin/activate"
        PYTHON_CMD="python"
        PIP_CMD="pip"
        STREAMLIT_CMD="streamlit"
        return 0
    elif [ -f "$PROJECT_ROOT/venv/bin/activate" ]; then
        echo -e "${GREEN}✓ Found venv in project, activating...${NC}"
        source "$PROJECT_ROOT/venv/bin/activate"
        PYTHON_CMD="python"
        PIP_CMD="pip"
        STREAMLIT_CMD="streamlit"
        return 0
    elif [ -f "$PROJECT_ROOT/.venv/bin/activate" ]; then
        echo -e "${GREEN}✓ Found .venv in project, activating...${NC}"
        source "$PROJECT_ROOT/.venv/bin/activate"
        PYTHON_CMD="python"
        PIP_CMD="pip"
        STREAMLIT_CMD="streamlit"
        return 0
    else
        echo -e "${GREEN}✓ Using system Python (system-wide installation)${NC}"
        PYTHON_CMD="python3"
        PIP_CMD="pip3"
        STREAMLIT_CMD="streamlit"
        return 1
    fi
}

# Function to get streamlit command path (for screen sessions that don't activate venv)
get_streamlit_cmd() {
    if [ -n "$VIRTUAL_ENV" ]; then
        echo "$VIRTUAL_ENV/bin/streamlit"
    elif [ -f "$PROJECT_ROOT/fintech_env/bin/streamlit" ]; then
        echo "$PROJECT_ROOT/fintech_env/bin/streamlit"
    elif [ -f "$PROJECT_ROOT/venv/bin/streamlit" ]; then
        echo "$PROJECT_ROOT/venv/bin/streamlit"
    elif [ -f "$PROJECT_ROOT/.venv/bin/streamlit" ]; then
        echo "$PROJECT_ROOT/.venv/bin/streamlit"
    else
        echo "streamlit"
    fi
}

# Function to check Python installation
check_python() {
    if ! command_exists python3; then
        echo -e "${RED}✗ Python 3 not found. Please install Python 3.8 or higher.${NC}"
        return 1
    fi
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}' | cut -d. -f1,2)
    echo -e "${GREEN}✓ Python ${PYTHON_VERSION} found${NC}"
    return 0
}

# Function to check and install Streamlit if needed
check_streamlit() {
    if [ "$STREAMLIT_CMD" = "streamlit" ]; then
        # Using system streamlit, check if it exists
        if ! command_exists streamlit; then
            echo -e "${YELLOW}✗ Streamlit not found. Installing...${NC}"
            $PIP_CMD install streamlit
            if [ $? -ne 0 ]; then
                echo -e "${RED}✗ Failed to install Streamlit. Please install manually: $PIP_CMD install streamlit${NC}"
                return 1
            fi
        fi
    elif [ -f "$STREAMLIT_CMD" ]; then
        # Using venv streamlit, verify it exists and is executable
        if [ ! -x "$STREAMLIT_CMD" ]; then
            echo -e "${RED}✗ Streamlit found but not executable: $STREAMLIT_CMD${NC}"
            return 1
        fi
    fi
    echo -e "${GREEN}✓ Streamlit found${NC}"
    return 0
}

# Function to check if port 8501 is in use
check_port() {
    PORT_IN_USE=false
    if command_exists ss; then
        if ss -tuln 2>/dev/null | grep -q ':8501 '; then
            PORT_IN_USE=true
        fi
    elif command_exists netstat; then
        if netstat -tuln 2>/dev/null | grep -q ':8501 '; then
            PORT_IN_USE=true
        fi
    fi
    
    if [ "$PORT_IN_USE" = true ]; then
        echo -e "${YELLOW}⚠ Port 8501 is already in use${NC}"
        echo "Stopping existing processes..."
        pkill -f "streamlit.*Stock_RAVA" 2>/dev/null || true
        sleep 2
    fi
}

