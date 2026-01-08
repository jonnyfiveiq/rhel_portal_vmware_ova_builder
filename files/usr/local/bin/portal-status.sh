#!/bin/bash
CONFIG_FILE="/etc/portal/.portal.env"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo "========================================"
echo "    Ansible Automation Portal Status"
echo "========================================"

# PostgreSQL
echo -n "PostgreSQL: "
if podman ps --format "{{.Names}}" 2>/dev/null | grep -q "portal-postgres"; then
    podman exec portal-postgres pg_isready -U portal_user &>/dev/null && echo -e "${GREEN}running${NC}" || echo -e "${YELLOW}starting${NC}"
else echo -e "${RED}stopped${NC}"; fi

# Portal
echo -n "Portal: "
if podman ps --format "{{.Names}}" 2>/dev/null | grep -q "^portal$"; then
    curl -sk https://localhost:7007/ &>/dev/null && echo -e "${GREEN}running${NC}" || echo -e "${YELLOW}starting${NC}"
else echo -e "${RED}stopped${NC}"; fi

# Config
echo ""
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
    echo "AAP URL: ${AAP_HOST_URL:-not set}"
    [[ "$AAP_HOST_URL" == *"CONFIGURE"* ]] && echo -e "${YELLOW}⚠ Portal NOT configured - set OVF properties${NC}"
fi

echo ""
echo "Access: https://$(hostname -I | awk '{print $1}'):7007"
echo "========================================"
