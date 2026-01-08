#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/portal-cloud-init.log"
CONFIG_FILE="/etc/portal/.portal.env"
CONFIGURED_FLAG="/etc/portal/.cloud-init-configured"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

[[ -f "$CONFIGURED_FLAG" ]] && { log "Already configured. Skipping."; exit 0; }

log "Starting Portal cloud-init configuration..."
mkdir -p /etc/portal

get_guestinfo() {
    local key="$1" default="${2:-}" value=""
    if command -v vmtoolsd &>/dev/null; then
        value=$(vmtoolsd --cmd "info-get guestinfo.${key}" 2>/dev/null || echo "")
        [[ -n "$value" ]] && { echo "$value"; return; }
    fi
    echo "$default"
}

log "Reading OVF properties..."

AAP_HOST_URL=$(get_guestinfo "portal.aap_host_url" "")
AAP_TOKEN=$(get_guestinfo "portal.aap_token" "")
OAUTH_CLIENT_ID=$(get_guestinfo "portal.oauth_client_id" "")
OAUTH_CLIENT_SECRET=$(get_guestinfo "portal.oauth_client_secret" "")
BASE_URL=$(get_guestinfo "portal.base_url" "https://localhost:7007")
HOSTNAME=$(get_guestinfo "portal.hostname" "portal-appliance")
BACKEND_SECRET=$(get_guestinfo "portal.backend_secret" "")
POSTGRESQL_PASSWORD=$(get_guestinfo "portal.postgresql_password" "")
POSTGRESQL_ADMIN_PASSWORD=$(get_guestinfo "portal.postgresql_admin_password" "")
SSH_PUBLIC_KEY=$(get_guestinfo "portal.ssh_public_key" "")

OVF_CONFIGURED=false
[[ -n "$AAP_HOST_URL" || -n "$AAP_TOKEN" ]] && OVF_CONFIGURED=true

[[ -z "$BACKEND_SECRET" ]] && { BACKEND_SECRET=$(openssl rand -base64 32); log "Generated BACKEND_SECRET"; }
[[ -z "$POSTGRESQL_PASSWORD" ]] && { POSTGRESQL_PASSWORD=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 20); log "Generated POSTGRESQL_PASSWORD"; }
[[ -z "$POSTGRESQL_ADMIN_PASSWORD" ]] && { POSTGRESQL_ADMIN_PASSWORD=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 20); log "Generated POSTGRESQL_ADMIN_PASSWORD"; }

[[ -z "$AAP_HOST_URL" ]] && AAP_HOST_URL="https://CONFIGURE-VIA-OVF-PROPERTIES"
[[ -z "$AAP_TOKEN" ]] && AAP_TOKEN="CONFIGURE-VIA-OVF-PROPERTIES"
[[ -z "$OAUTH_CLIENT_ID" ]] && OAUTH_CLIENT_ID="CONFIGURE-VIA-OVF-PROPERTIES"
[[ -z "$OAUTH_CLIENT_SECRET" ]] && OAUTH_CLIENT_SECRET="CONFIGURE-VIA-OVF-PROPERTIES"

log "Writing configuration..."
cat > "$CONFIG_FILE" << EOF
# Portal Configuration - Generated $(date)
# OVF Configured: ${OVF_CONFIGURED}

PORTAL_ENVIRONMENT=production
BASE_URL=${BASE_URL}
GITHUB_URL=github.com
GITLAB_URL=gitlab.com

USE_EXTERNAL_POSTGRES=false
POSTGRESQL_HOST=portal-postgres
POSTGRESQL_PORT=5432
POSTGRESQL_USER=portal_user
POSTGRESQL_PASSWORD=${POSTGRESQL_PASSWORD}
POSTGRESQL_DATABASE=portal_db
POSTGRESQL_ADMIN_PASSWORD=${POSTGRESQL_ADMIN_PASSWORD}

BACKEND_SECRET=${BACKEND_SECRET}

AAP_HOST_URL=${AAP_HOST_URL}
AAP_TOKEN=${AAP_TOKEN}
OAUTH_CLIENT_ID=${OAUTH_CLIENT_ID}
OAUTH_CLIENT_SECRET=${OAUTH_CLIENT_SECRET}

NODE_TLS_REJECT_UNAUTHORIZED=0
EOF
chmod 600 "$CONFIG_FILE"

if [[ -n "$SSH_PUBLIC_KEY" ]]; then
    log "Configuring SSH key for root..."
    mkdir -p /root/.ssh && chmod 700 /root/.ssh
    echo "$SSH_PUBLIC_KEY" >> /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    [[ -d /var/roothome ]] && {
        mkdir -p /var/roothome/.ssh && chmod 700 /var/roothome/.ssh
        echo "$SSH_PUBLIC_KEY" >> /var/roothome/.ssh/authorized_keys
        chmod 600 /var/roothome/.ssh/authorized_keys
    }
fi

[[ "$HOSTNAME" != "portal-appliance" ]] && hostnamectl set-hostname "$HOSTNAME" || true

touch "$CONFIGURED_FLAG"
log "Configuration complete!"
