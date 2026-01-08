# RHEL Portal VMware OVA Builder

Build a VMware OVA appliance for the Ansible Automation Portal.

## Prerequisites

- RHEL 9 build host with `podman`, `ansible-core`, `qemu-img`
- Red Hat registry credentials
- Portal bootc image (`rhaap-portal-latest.tar.gz`)

## Build

```bash
# 1. Clone and enter directory
git clone https://github.com/jonnyfiveiq/rhel_portal_vmware_ova_builder.git
cd rhel_portal_vmware_ova_builder

# 2. Login to Red Hat registry
podman login registry.redhat.io

# 3. Place the portal image tarball here
cp /path/to/rhaap-portal-latest.tar.gz .

# 4. Build OVA (does everything)
sudo -E ansible-playbook build-ova.yml
```

Output: `vmdk-output/portal-appliance.ova`

## Deploy

1. Upload OVA to vSphere/ESXi
2. Deploy from OVF template
3. Set OVF properties:
   - AAP Host URL
   - AAP API Token
   - OAuth Client ID
   - OAuth Client Secret
4. Power on → Access `https://<VM-IP>:7007`

**Default credentials:** `root` / `PortalAdmin123!`

## Troubleshooting

```bash
ssh root@<VM-IP>
portal-status.sh      # Check status
health-check.sh       # Run health checks
portal-reconfigure    # Re-run configuration
```
