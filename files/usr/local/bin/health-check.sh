#!/bin/bash
EXIT=0
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'

echo "Portal Health Check"
echo "==================="

echo -n "PostgreSQL: "
podman exec portal-postgres pg_isready -U portal_user &>/dev/null && echo -e "${GREEN}OK${NC}" || { echo -e "${RED}FAIL${NC}"; EXIT=1; }

echo -n "Portal HTTP: "
HTTP=$(curl -sk -o /dev/null -w "%{http_code}" https://localhost:7007/ 2>/dev/null)
[[ "$HTTP" == "200" ]] && echo -e "${GREEN}OK${NC}" || { echo -e "${RED}FAIL ($HTTP)${NC}"; EXIT=1; }

echo -n "Config: "
source /etc/portal/.portal.env 2>/dev/null
[[ "$AAP_HOST_URL" != *"CONFIGURE"* ]] && echo -e "${GREEN}OK${NC}" || { echo -e "${RED}NOT CONFIGURED${NC}"; EXIT=1; }

exit $EXIT
