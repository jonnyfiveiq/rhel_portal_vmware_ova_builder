# Containerfile for Portal VMware Appliance
FROM quay.io/audgirka/rhaap-portal-image:latest

# Install VMware tools and cloud-init
RUN dnf install -y open-vm-tools cloud-init cloud-utils-growpart && dnf clean all

# Remove default SSH config that disables password auth
RUN rm -f /etc/ssh/sshd_config.d/10-disable-password-auth.conf

# Copy configurations
COPY files/etc/ssh/sshd_config.d/99-allow-password.conf /etc/ssh/sshd_config.d/
COPY files/etc/cloud/cloud.cfg.d/99_portal.cfg /etc/cloud/cloud.cfg.d/

# Copy portal scripts
COPY files/usr/local/bin/portal-cloud-init.sh /usr/local/bin/
COPY files/usr/local/bin/portal-status.sh /usr/local/bin/
COPY files/usr/local/bin/portal-reconfigure /usr/local/bin/
COPY files/usr/local/bin/health-check.sh /usr/local/bin/

# Make scripts executable
RUN chmod +x /usr/local/bin/portal-*.sh /usr/local/bin/portal-reconfigure /usr/local/bin/health-check.sh

# Create portal config directory
RUN mkdir -p /etc/portal

# Set default root password: PortalAdmin123!
RUN echo 'root:PortalAdmin123!' | chpasswd

# Enable services
RUN systemctl enable vmtoolsd.service cloud-init.service cloud-init-local.service cloud-config.service cloud-final.service || true

LABEL name="portal-vmdk" vendor="Red Hat" version="1.0"
