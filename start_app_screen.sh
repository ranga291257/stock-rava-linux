#!/bin/bash
# Bash script to run Stock RAVA in a GNU Screen session
# Usage: ./start_app_screen.sh
# Reattach with: screen -r stock_rava

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/app_common.sh"

# Screen session name
SESSION_NAME="stock_rava"

# Check if screen is installed
if ! command_exists screen; then
    echo -e "${YELLOW}GNU Screen not found. Installing...${NC}"
    if command_exists apt-get; then
        sudo apt-get update && sudo apt-get install -y screen
    elif command_exists yum; then
        sudo yum install -y screen
    elif command_exists dnf; then
        sudo dnf install -y screen
    else
        echo -e "${RED}✗ Please install GNU Screen manually${NC}"
        exit 1
    fi
fi

# Check Python
check_python || exit 1

# Get streamlit command (for screen we use full path, not activate)
STREAMLIT_CMD=$(get_streamlit_cmd)

# Check Streamlit
if [ "$STREAMLIT_CMD" = "streamlit" ]; then
    if ! command_exists streamlit; then
        echo -e "${YELLOW}✗ Streamlit not found. Installing...${NC}"
        pip3 install streamlit
    fi
fi

# Check if session already exists
if screen -list | grep -q "$SESSION_NAME"; then
    echo -e "${YELLOW}⚠ Screen session '$SESSION_NAME' already exists${NC}"
    echo "Reattaching to existing session..."
    screen -r "$SESSION_NAME"
    exit 0
fi

# Start new screen session
echo -e "${CYAN}Starting Stock RAVA in GNU Screen session '$SESSION_NAME'...${NC}"
echo -e "${CYAN}App will be available at: http://localhost:8501${NC}"

# Create detached screen session and run Streamlit
# Use appropriate venv activation or system Python
if [ -f "$PROJECT_ROOT/fintech_env/bin/activate" ]; then
    screen -dmS "$SESSION_NAME" bash -c "cd '$PROJECT_ROOT' && source fintech_env/bin/activate && streamlit run Stock_RAVA.py --server.headless true; exec bash"
elif [ -f "$PROJECT_ROOT/venv/bin/activate" ]; then
    screen -dmS "$SESSION_NAME" bash -c "cd '$PROJECT_ROOT' && source venv/bin/activate && streamlit run Stock_RAVA.py --server.headless true; exec bash"
elif [ -f "$PROJECT_ROOT/.venv/bin/activate" ]; then
    screen -dmS "$SESSION_NAME" bash -c "cd '$PROJECT_ROOT' && source .venv/bin/activate && streamlit run Stock_RAVA.py --server.headless true; exec bash"
else
    screen -dmS "$SESSION_NAME" bash -c "cd '$PROJECT_ROOT' && streamlit run Stock_RAVA.py --server.headless true; exec bash"
fi

sleep 2

# Verify session is running
if screen -list | grep -q "$SESSION_NAME"; then
    echo -e "${GREEN}✓ Stock RAVA started in screen session '$SESSION_NAME'${NC}"
    echo ""
    echo -e "${CYAN}Useful commands:${NC}"
    echo "  Reattach:     screen -r $SESSION_NAME"
    echo "  Detach:       Press Ctrl+A, then D"
    echo "  List sessions: screen -list"
    echo "  Kill session: screen -X -S $SESSION_NAME quit"
    echo ""
    echo -e "${YELLOW}Reattaching to session in 3 seconds... (Press Ctrl+A then D to detach)${NC}"
    sleep 3
    screen -r "$SESSION_NAME"
else
    echo -e "${RED}✗ Failed to start screen session${NC}"
    exit 1
fi
