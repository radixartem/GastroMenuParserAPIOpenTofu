# GastroMenuParserAPI

Production-ready ASP.NET Core API for importing menu data from `essen-auf-raedern-eichsfeld.de`, PostgreSQL persistence, Docker Compose deployment and Prometheus/Grafana/Loki observability.

## Current baseline

- Ubuntu 26.04 LTS on the existing Hetzner server
- .NET 10 LTS / ASP.NET Core 10
- PostgreSQL 16
- Docker Engine + Compose V2 from the official Docker repository
- Caddy 2 with automatic HTTPS
- Prometheus + Grafana + Loki + Grafana Alloy
- GitHub Actions → GHCR → SSH deployment
- PostgreSQL backups to S3-compatible Hetzner Object Storage

Docker officially supports Ubuntu 26.04 (Resolute). .NET 10 is the current LTS release. The Terraform configuration uses Hetzner provider 1.66.1 and deliberately treats the existing production server as a data source rather than a managed resource.

## First deployment

1. On the Ubuntu 26.04 server, make sure DNS for `gastro.opik.net` points to the server.
2. Install Ansible collections:

```bash
ansible-galaxy collection install -r ops/ansible/requirements.yml
```

3. Bootstrap the server:

```bash
export PRODUCTION_IP=YOUR_SERVER_IP
ansible-playbook -i ops/ansible/inventory/hosts.yml ops/ansible/playbooks/bootstrap.yml
```

4. Create GitHub Actions environment `production` and add:

- `PROD_SERVER_IP`
- `PROD_DEPLOY_USER` = `deploy`
- `PROD_SSH_KEY`
- `PROD_KNOWN_HOSTS`
- `PROD_POSTGRES_PASSWORD`
- `PROD_GRAFANA_PASSWORD`
- `PROD_IMPORT_API_KEY`
- `GHCR_USERNAME`
- `GHCR_READ_TOKEN` with `read:packages`
- `ACME_EMAIL`
- `OBJ_ACCESS_KEY`
- `OBJ_SECRET_KEY`
- `OBJ_ENDPOINT`
- `OBJ_BUCKET`

5. Push to `main`. Build tests the application, builds the immutable SHA image, pushes it to GHCR, and deploys that SHA to the production server.

## Manual first deployment

Copy the repository to `/opt/gastro-api`, create `/opt/gastro-api/.env` from `.env.example`, then:

```bash
cd /opt/gastro-api
docker compose --env-file .env pull
docker compose --env-file .env up -d
```

Start monitoring:

```bash
docker compose --env-file .env -f docker-compose.monitoring.yml up -d
```

## Verification

```bash
docker compose --env-file .env ps
curl -I https://gastro.opik.net
curl https://gastro.opik.net/api/menu
```

Internal health checks are available from inside the Docker network at `/health/live` and `/health/ready`. `/metrics` is intentionally not proxied publicly by Caddy; Prometheus accesses `api:8080/metrics` internally.

Grafana and Prometheus are bound to `127.0.0.1` on the host. Access Grafana through an SSH tunnel:

```bash
ssh -L 3000:127.0.0.1:3000 deploy@YOUR_SERVER_IP
```

Then open `http://localhost:3000`.

## Backups

Install the timer:

```bash
sudo /usr/local/bin/gastro-install-systemd
systemctl list-timers gastro-backup.timer
```

Manual backup:

```bash
sudo /usr/local/bin/gastro-backup
```

Restore:

```bash
sudo /opt/gastro-api/ops/backups/restore.sh /path/to/postgres_YYYYMMDDTHHMMSSZ.dump
```

## Terraform

Production Terraform is intentionally non-destructive: it reads the existing Hetzner server, firewall and volume. It does not create or destroy the current production server.

```bash
cd terraform/live/production
cp backend.hcl.example backend.hcl
# edit endpoint/bucket
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
terraform init -backend-config=backend.hcl
terraform plan -var='hcloud_token=...' -var='existing_server_id=...'
```

## Important security notes

- Never commit `.env`, backend credentials, SSH private keys or GHCR tokens.
- Do not expose PostgreSQL, Prometheus, Grafana, Loki, cAdvisor or Node Exporter ports to the Internet.
- Docker-published ports can bypass UFW rules; this stack only publishes Caddy's 80/443 publicly and binds observability services to loopback.
- Do not enable volume formatting for an existing PostgreSQL volume unless it is known to be empty.
