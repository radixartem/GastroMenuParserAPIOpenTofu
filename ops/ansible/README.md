# Ansible

Install collections:

```bash
ansible-galaxy collection install -r requirements.yml
```

Bootstrap the existing Ubuntu 26.04   server:

```bash
export PRODUCTION_IP=YOUR_SERVER_IP
ansible-playbook -i inventory/hosts.yml playbooks/bootstrap.yml
```

If a dedicated Hetzner Volume is already attached and should be mounted, set:

```bash
export POSTGRES_VOLUME_DEVICE=/dev/disk/by-id/scsi-0HC_Volume_YOUR_ID
```

The playbook deliberately does **not** format a volume. Only set `format_postgres_volume=true` for a known-empty volume.
