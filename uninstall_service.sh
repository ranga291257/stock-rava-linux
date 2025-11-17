#!/bin/bash
# Script to uninstall Stock RAVA systemd user service
# Usage: ./uninstall_service.sh

set -e

SERVICE_NAME="stock-rava.service"
USER_SERVICE_DIR="$HOME/.config/systemd/user"
SERVICE_FILE="$USER_SERVICE_DIR/$SERVICE_NAME"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Uninstalling Stock RAVA systemd service...${NC}"
echo ""

# Check if service exists
if [ ! -f "$SERVICE_FILE" ]; then
    echo -e "${YELLOW}⚠ Service file not found: $SERVICE_FILE${NC}"
    echo "Service may not be installed."
    exit 0
fi

# Stop service if running
if systemctl --user is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
    echo -e "${CYAN}Stopping service...${NC}"
    systemctl --user stop "$SERVICE_NAME"
    echo -e "${GREEN}✓ Service stopped${NC}"
fi

# Disable service
if systemctl --user is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
    echo -e "${CYAN}Disabling service...${NC}"
    systemctl --user disable "$SERVICE_NAME"
    echo -e "${GREEN}✓ Service disabled${NC}"
fi

# Remove service file
echo -e "${CYAN}Removing service file...${NC}"
rm -f "$SERVICE_FILE"
echo -e "${GREEN}✓ Service file removed${NC}"

# Reload systemd
echo -e "${CYAN}Reloading systemd...${NC}"
systemctl --user daemon-reload
echo -e "${GREEN}✓ Systemd reloaded${NC}"

echo ""
echo -e "${GREEN}✓ Uninstallation complete!${NC}"
echo ""
echo -e "${CYAN}The service has been removed and will not start on login.${NC}"


