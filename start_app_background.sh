#!/bin/bash
# Bash script to run Stock RAVA in background on Linux
# Usage: ./start_app_background.sh

set -e  # Exit on error

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/app_common.sh"

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
check_python || exit 1

# Setup Python environment (venv or system)
setup_python_env

# Check Streamlit
check_streamlit || exit 1

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

# Check port
check_port

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
