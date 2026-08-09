# Production deployment: Ubuntu 26.04 + Hetzner

This repository targets an **existing** Hetzner Cloud server running Ubuntu 26.04 LTS. The production Terraform configuration is intentionally non-destructive and reads the existing server instead of creating a replacement.

## 1. DNS

Create/verify an A record:

```text
gastro.opik.net -> SERVER_PUBLIC_IPV4
```

Ports 80 and 443 must be reachable from the Internet.

## 2. Bootstrap Ubuntu 26.04

From a workstation with Ansible:

```bash
ansible-galaxy collection install -r ops/ansible/requirements.yml
export PRODUCTION_IP=SERVER_PUBLIC_IPV4
ansible-playbook -i ops/ansible/inventory/hosts.yml ops/ansible/playbooks/bootstrap.yml
```

The playbook installs Docker Engine and Compose V2 from Docker's official APT repository, creates `deploy`, configures UFW/fail2ban and prepares `/srv/gastro/postgres`.

### Existing Hetzner Volume

If PostgreSQL should use a dedicated Hetzner Volume, find its device on the server:

```bash
ls -l /dev/disk/by-id/ | grep -i volume
lsblk -f
```

Then run bootstrap with:

```bash
export POSTGRES_VOLUME_DEVICE=/dev/disk/by-id/scsi-0HC_Volume_ID
ansible-playbook -i ops/ansible/inventory/hosts.yml ops/ansible/playbooks/bootstrap.yml
```

The playbook does **not** format an existing volume. Never enable formatting for a volume containing data.

## 3. GitHub Container Registry

The build workflow publishes:

```text
ghcr.io/radixartem/gastromenuparserapi:<commit-sha>
ghcr.io/radixartem/gastromenuparserapi:latest
```

For a private package create a GitHub token with `read:packages` for the deployment server. Store it as `GHCR_READ_TOKEN`.

## 4. GitHub production environment

Create repository environment `production` and configure:

```text
PROD_SERVER_IP
PROD_DEPLOY_USER=deploy
PROD_SSH_KEY
PROD_KNOWN_HOSTS
PROD_POSTGRES_PASSWORD
PROD_GRAFANA_PASSWORD
PROD_IMPORT_API_KEY
GHCR_USERNAME
GHCR_READ_TOKEN
ACME_EMAIL
OBJ_ACCESS_KEY
OBJ_SECRET_KEY
OBJ_ENDPOINT
OBJ_BUCKET
```

`PROD_KNOWN_HOSTS` should contain the output of:

```bash
ssh-keyscan -H SERVER_PUBLIC_IPV4
```

## 5. First deployment

Push the repository to `main`.

The pipeline performs:

```text
unit/integration tests
        ↓
Docker build
        ↓
GHCR push with commit SHA
        ↓
SSH upload of runtime configuration
        ↓
GHCR login on server
        ↓
docker compose pull
        ↓
docker compose up
        ↓
monitoring compose up
        ↓
backup timer installation
```

The production image is deployed by SHA, not by `latest`.

## 6. Application

After deployment:

```bash
ssh deploy@SERVER_PUBLIC_IPV4
cd /opt/gastro-api
docker compose --env-file .env ps
```

Check:

```bash
curl -I https://gastro.opik.net
curl https://gastro.opik.net/api/menu
```

Import requires:

```bash
curl -X POST \
  -H 'X-Import-Key: YOUR_IMPORT_API_KEY' \
  'https://gastro.opik.net/api/menu/import'
```

The import URL, if supplied, must be HTTPS. This prevents the public API from becoming a generic HTTP/SSRF proxy.

## 7. Monitoring

The monitoring stack is not publicly exposed.

Create an SSH tunnel:

```bash
ssh -L 3000:127.0.0.1:3000 deploy@SERVER_PUBLIC_IPV4
```

Open:

```text
http://localhost:3000
```

Prometheus:

```bash
ssh -L 9090:127.0.0.1:9090 deploy@SERVER_PUBLIC_IPV4
```

Alloy UI:

```bash
ssh -L 12345:127.0.0.1:12345 deploy@SERVER_PUBLIC_IPV4
```

## 8. Backups

The deployment installs a systemd timer:

```bash
systemctl status gastro-backup.timer
systemctl list-timers gastro-backup.timer
```

Run manually:

```bash
sudo /usr/local/bin/gastro-backup
```

Backups are PostgreSQL custom-format dumps stored in the configured S3-compatible Object Storage bucket.

## 9. Restore

Copy the desired dump to the server and run:

```bash
sudo /opt/gastro-api/ops/backups/restore.sh /path/to/postgres_YYYYMMDDTHHMMSSZ.dump
```

The script requires typing `RESTORE` and temporarily stops the API before restoring the database.

## 10. Existing database safety

The GitHub deployment workflow checks whether an existing `gastro-postgres` container is present while `/srv/gastro/postgres` is empty. If so, deployment stops instead of silently starting a new empty database.

If the current production database is stored in an old Docker named volume, migrate it explicitly before switching to the bind-mounted PostgreSQL directory.

## 11. Terraform

Production Terraform only reads:

- existing server;
- existing firewall;
- existing PostgreSQL volume.

Configure `terraform/live/production/backend.hcl` from the example and provide Object Storage credentials:

```bash
cd terraform/live/production
cp backend.hcl.example backend.hcl
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
terraform init -backend-config=backend.hcl
terraform plan \
  -var='hcloud_token=...' \
  -var='existing_server_id=12345678' \
  -var='existing_firewall_id=12345678' \
  -var='existing_volume_id=12345678'
```

A production `terraform apply` is intentionally not part of the application deployment workflow.
