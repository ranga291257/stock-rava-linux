#!/bin/bash
# Script to install Stock RAVA desktop shortcut
# Usage: ./install_desktop.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESKTOP_FILE="$SCRIPT_DIR/stock-rava.desktop"
DESKTOP_DIR="$HOME/.local/share/applications"
DESKTOP_DEST="$DESKTOP_DIR/stock-rava.desktop"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Installing Stock RAVA desktop shortcut...${NC}"
echo ""

# Check if desktop file exists
if [ ! -f "$DESKTOP_FILE" ]; then
    echo -e "${RED}✗ Desktop file not found: $DESKTOP_FILE${NC}"
    exit 1
fi

# Create applications directory if it doesn't exist
mkdir -p "$DESKTOP_DIR"

# Copy desktop file
echo -e "${CYAN}Copying desktop file...${NC}"
cp "$DESKTOP_FILE" "$DESKTOP_DEST"
echo -e "${GREEN}✓ Desktop file copied to: $DESKTOP_DEST${NC}"

# Make it executable (required for desktop files)
chmod +x "$DESKTOP_DEST"
echo -e "${GREEN}✓ Desktop file made executable${NC}"

# Update desktop database (so it appears in application menu)
if command -v update-desktop-database >/dev/null 2>&1; then
    echo -e "${CYAN}Updating desktop database...${NC}"
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
    echo -e "${GREEN}✓ Desktop database updated${NC}"
fi

echo ""
echo -e "${GREEN}✓ Installation complete!${NC}"
echo ""
echo -e "${CYAN}The Stock RAVA shortcut has been installed.${NC}"
echo -e "${CYAN}You can now:${NC}"
echo "  1. Find 'Stock RAVA' in your application menu"
echo "  2. Pin it to your dock/taskbar for quick access"
echo "  3. Double-click the desktop file to open the app"
echo ""
echo -e "${YELLOW}Note: Make sure the app is running (http://localhost:8501)${NC}"
echo -e "${YELLOW}      before clicking the shortcut.${NC}"
echo ""
echo -e "${CYAN}To uninstall, run:${NC}"
echo "  rm -f $DESKTOP_DEST"
if command -v update-desktop-database >/dev/null 2>&1; then
    echo "  update-desktop-database $DESKTOP_DIR"
fi

