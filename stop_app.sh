#!/bin/bash
# Bash script to stop Stock RAVA background process
# Usage: ./stop_app.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SCRIPT_DIR/stock_rava.pid"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "Stopping Stock RAVA..."

# Method 1: Stop via PID file
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo -e "${YELLOW}Stopping process (PID: $PID)...${NC}"
        kill "$PID" 2>/dev/null
        
        # Wait for graceful shutdown
        for i in {1..10}; do
            if ! ps -p "$PID" > /dev/null 2>&1; then
                break
            fi
            sleep 1
        done
        
        # Force kill if still running
        if ps -p "$PID" > /dev/null 2>&1; then
            echo -e "${YELLOW}Force killing process...${NC}"
            kill -9 "$PID" 2>/dev/null
        fi
        
        echo -e "${GREEN}✓ Stopped Stock RAVA (PID: $PID)${NC}"
    else
        echo -e "${YELLOW}⚠ PID file exists but process not running${NC}"
    fi
    rm -f "$PID_FILE"
else
    echo -e "${YELLOW}⚠ No PID file found${NC}"
fi

# Method 2: Kill any remaining Streamlit processes running Stock_RAVA
echo "Checking for remaining Streamlit processes..."
STREAMLIT_PIDS=$(pgrep -f "streamlit.*Stock_RAVA" 2>/dev/null || true)

if [ -n "$STREAMLIT_PIDS" ]; then
    echo -e "${YELLOW}Found additional Streamlit processes, stopping...${NC}"
    for pid in $STREAMLIT_PIDS; do
        kill "$pid" 2>/dev/null || true
    done
    sleep 2
    
    # Force kill if still running
    STREAMLIT_PIDS=$(pgrep -f "streamlit.*Stock_RAVA" 2>/dev/null || true)
    if [ -n "$STREAMLIT_PIDS" ]; then
        for pid in $STREAMLIT_PIDS; do
            kill -9 "$pid" 2>/dev/null || true
        done
    fi
    echo -e "${GREEN}✓ Stopped additional Streamlit processes${NC}"
fi

# Method 3: Check for screen session
if command_exists screen; then
    if screen -list 2>/dev/null | grep -q "stock_rava"; then
        echo -e "${YELLOW}Found screen session 'stock_rava', stopping...${NC}"
        screen -X -S stock_rava quit 2>/dev/null || true
        echo -e "${GREEN}✓ Stopped screen session${NC}"
    fi
fi

# Check port 8501
if command_exists ss; then
    PORT_CHECK=$(ss -tuln 2>/dev/null | grep ':8501 ' || true)
elif command_exists netstat; then
    PORT_CHECK=$(netstat -tuln 2>/dev/null | grep ':8501 ' || true)
fi

if [ -z "$PORT_CHECK" ]; then
    echo -e "${GREEN}✓ Port 8501 is now free${NC}"
else
    echo -e "${YELLOW}⚠ Port 8501 may still be in use${NC}"
fi

echo ""
echo -e "${GREEN}✓ Stock RAVA stopped successfully${NC}"


