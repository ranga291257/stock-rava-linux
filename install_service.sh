#!/bin/bash
# Script to install Stock RAVA as a systemd user service
# Usage: ./install_service.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
SERVICE_FILE="$SCRIPT_DIR/stock-rava.service"
SERVICE_NAME="stock-rava.service"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Installing Stock RAVA as systemd user service...${NC}"
echo ""

# Check if running as root (we want user service, not system service)
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}✗ Do not run this script as root${NC}"
    echo "This installs a user service. Run as a regular user."
    exit 1
fi

# Check if systemd is available
if ! systemctl --user list-units > /dev/null 2>&1; then
    echo -e "${RED}✗ systemd user services not available${NC}"
    echo "Make sure you're running on a systemd-based Linux distribution (Ubuntu, Debian, etc.)"
    exit 1
fi

# User service directory
USER_SERVICE_DIR="$HOME/.config/systemd/user"
mkdir -p "$USER_SERVICE_DIR"

# Detect virtual environment if present (checks fintech_env first)
PYTHON_CMD=$(which python3)
VENV_PATH=""

if [ -f "$PROJECT_ROOT/fintech_env/bin/python" ]; then
    PYTHON_CMD="$PROJECT_ROOT/fintech_env/bin/python"
    VENV_PATH="$PROJECT_ROOT/fintech_env/bin:"
    echo -e "${GREEN}✓ Using fintech_env Python: $PYTHON_CMD${NC}"
    echo -e "${CYAN}  (Recommended: keeps system Python clean)${NC}"
elif [ -f "$PROJECT_ROOT/venv/bin/python" ]; then
    PYTHON_CMD="$PROJECT_ROOT/venv/bin/python"
    VENV_PATH="$PROJECT_ROOT/venv/bin:"
    echo -e "${GREEN}✓ Using venv Python: $PYTHON_CMD${NC}"
elif [ -f "$PROJECT_ROOT/.venv/bin/python" ]; then
    PYTHON_CMD="$PROJECT_ROOT/.venv/bin/python"
    VENV_PATH="$PROJECT_ROOT/.venv/bin:"
    echo -e "${GREEN}✓ Using .venv Python: $PYTHON_CMD${NC}"
else
    echo -e "${YELLOW}⚠ No virtual environment detected${NC}"
    echo -e "${YELLOW}  Recommendation: Create fintech_env before installing service${NC}"
    echo -e "${YELLOW}  Run: python3 -m venv fintech_env && source fintech_env/bin/activate && pip install -r requirements_app.txt${NC}"
fi

# Create service file with actual paths
echo -e "${CYAN}Creating service file...${NC}"
cat > "$USER_SERVICE_DIR/$SERVICE_NAME" << EOF
[Unit]
Description=Stock RAVA - Risk And Volatility Analysis Dashboard
After=network.target

[Service]
Type=simple
WorkingDirectory=$PROJECT_ROOT
Environment="PATH=$VENV_PATH$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=$PYTHON_CMD -m streamlit run $PROJECT_ROOT/Stock_RAVA.py --server.headless true --server.port 8501
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=stock-rava

# Security settings
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=default.target
EOF

echo -e "${GREEN}✓ Service file created at: $USER_SERVICE_DIR/$SERVICE_NAME${NC}"

# Reload systemd
echo -e "${CYAN}Reloading systemd...${NC}"
systemctl --user daemon-reload
echo -e "${GREEN}✓ Systemd reloaded${NC}"

# Enable service (start on login)
echo -e "${CYAN}Enabling service (auto-start on login)...${NC}"
systemctl --user enable "$SERVICE_NAME"
echo -e "${GREEN}✓ Service enabled${NC}"

# Ask if user wants to start now
echo ""
read -p "Start the service now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    systemctl --user start "$SERVICE_NAME"
    echo -e "${GREEN}✓ Service started${NC}"
    
    # Wait a moment and check status
    sleep 2
    systemctl --user status "$SERVICE_NAME" --no-pager || true
fi

echo ""
echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""
echo -e "${CYAN}Useful commands:${NC}"
echo "  Start service:   systemctl --user start $SERVICE_NAME"
echo "  Stop service:    systemctl --user stop $SERVICE_NAME"
echo "  Status:          systemctl --user status $SERVICE_NAME"
echo "  View logs:       journalctl --user -u $SERVICE_NAME -f"
echo "  Disable:         systemctl --user disable $SERVICE_NAME"
echo ""
echo -e "${CYAN}The service will automatically start on login.${NC}"

