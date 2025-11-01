#!/bin/bash
# Bash script to check Stock RAVA status
# Usage: ./status_app.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SCRIPT_DIR/stock_rava.pid"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo -e "${CYAN}Stock RAVA Status Check${NC}"
echo "=========================="
echo ""

# Check PID file
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Status: RUNNING${NC}"
        echo -e "  PID: $PID"
        
        # Get process info
        if command_exists ps; then
            PROCESS_INFO=$(ps -p "$PID" -o pid,user,%cpu,%mem,etime,cmd --no-headers 2>/dev/null || true)
            if [ -n "$PROCESS_INFO" ]; then
                echo -e "  Process Info:"
                echo "$PROCESS_INFO" | awk '{print "    User: "$2", CPU: "$3"%, MEM: "$4"%, Runtime: "$5}'
            fi
        fi
    else
        echo -e "${RED}✗ Status: NOT RUNNING (stale PID file)${NC}"
        echo "  PID file exists but process not found"
    fi
else
    echo -e "${YELLOW}⚠ Status: UNKNOWN (no PID file)${NC}"
fi

echo ""

# Check for any Streamlit processes
STREAMLIT_PIDS=$(pgrep -f "streamlit.*Stock_RAVA" 2>/dev/null || true)
if [ -n "$STREAMLIT_PIDS" ]; then
    echo -e "${GREEN}✓ Found Streamlit processes:${NC}"
    for pid in $STREAMLIT_PIDS; do
        if command_exists ps; then
            ps -p "$pid" -o pid,user,etime,cmd --no-headers 2>/dev/null | awk '{print "  PID: "$1", User: "$2", Runtime: "$3}'
        else
            echo "  PID: $pid"
        fi
    done
else
    echo -e "${YELLOW}⚠ No Streamlit processes found${NC}"
fi

echo ""

# Check port 8501
echo -e "${CYAN}Port 8501 Status:${NC}"
if command_exists ss; then
    PORT_INFO=$(ss -tuln 2>/dev/null | grep ':8501 ' || true)
elif command_exists netstat; then
    PORT_INFO=$(netstat -tuln 2>/dev/null | grep ':8501 ' || true)
fi

if [ -n "$PORT_INFO" ]; then
    echo -e "${GREEN}✓ Port 8501 is in use${NC}"
    if command_exists lsof; then
        LSOF_INFO=$(lsof -i :8501 2>/dev/null | tail -n +2 || true)
        if [ -n "$LSOF_INFO" ]; then
            echo "$LSOF_INFO" | awk '{print "  PID: "$2", User: "$3", Command: "$1}'
        fi
    fi
else
    echo -e "${YELLOW}⚠ Port 8501 is not in use${NC}"
fi

echo ""

# Check screen session
if command_exists screen; then
    echo -e "${CYAN}Screen Sessions:${NC}"
    if screen -list 2>/dev/null | grep -q "stock_rava"; then
        echo -e "${GREEN}✓ Found screen session 'stock_rava'${NC}"
        screen -list | grep stock_rava
    else
        echo -e "${YELLOW}⚠ No screen session 'stock_rava' found${NC}"
    fi
fi

echo ""
echo -e "${CYAN}Quick Actions:${NC}"
echo "  Start:  ./start_app_background.sh"
echo "  Stop:    ./stop_app.sh"
echo "  Status:  ./status_app.sh"


