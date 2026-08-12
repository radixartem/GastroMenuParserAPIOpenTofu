# GastroMenuParserAPI

Production-ready ASP.NET Core API for importing menu data from `essen-auf-raedern-eichsfeld.de`, PostgreSQL persistence, Docker Compose deployment, and Prometheus/Grafana/Loki observability.

Infrastructure is managed with OpenTofu, server configuration with Ansible, and CI/CD with GitHub Actions.

## Current stack

- **OS:** Ubuntu 26.04 LTS on Hetzner Cloud
- **Runtime:** .NET 10 LTS / ASP.NET Core 10
- **Database:** PostgreSQL 16 (data on a separate Hetzner Volume)
- **Containerisation:** Docker Engine + Compose V2 (official Docker repository)
- **Reverse proxy:** Caddy 2 with automatic HTTPS
- **Monitoring:** Prometheus + Grafana + Loki + Grafana Alloy
- **CI/CD:** GitHub Actions → GHCR → SSH deployment
- **Backups:** S3-compatible Hetzner Object Storage
- **Infrastructure as Code:** OpenTofu 1.12.x (manages Hetzner resources: server, volume, firewall)
- **Configuration management:** Ansible (OS setup, Docker, services)

## First deployment

### 1. Configure DNS

Ensure DNS for `gastro.opik.net` points to your server IP.

### 2. Install Ansible collections

```bash
ansible-galaxy collection install -r ops/ansible/requirements.yml
```

If the server already exists in Hetzner, obtain its IP, for example via `tofu output servers` after import as described in [Infrastructure management](#infrastructure-management).

Bootstrap the server:

```bash
export PRODUCTION_IP=YOUR_SERVER_IP

ansible-playbook \
  -i ops/ansible/inventory/hosts.yml \
  ops/ansible/playbooks/bootstrap.yml
```

The server is now ready for application deployment.

### 3. Configure GitHub Environment and secrets

Create a GitHub Environment named `production` and add the following secrets.

#### Application deployment

- `PROD_SERVER_IP` — production server IP
- `PROD_DEPLOY_USER` — `deploy`
- `PROD_SSH_KEY` — private SSH key
- `PROD_KNOWN_HOSTS` — server's `known_hosts` entry
- `PROD_POSTGRES_PASSWORD` — PostgreSQL password
- `PROD_GRAFANA_PASSWORD` — Grafana admin password
- `PROD_IMPORT_API_KEY` — API key for menu import endpoints
- `GHCR_USERNAME` — GitHub Packages username
- `GHCR_READ_TOKEN` — token with `read:packages` scope
- `ACME_EMAIL` — email for Let's Encrypt / Caddy
- `OBJ_ACCESS_KEY` — Hetzner Object Storage access key
- `OBJ_SECRET_KEY` — Object Storage secret key
- `OBJ_ENDPOINT` — Object Storage endpoint
- `OBJ_BUCKET` — backup bucket name

#### OpenTofu CI: plan and apply

- `HCLOUD_TOKEN` — Hetzner Cloud API token
- `SSH_KEY_IDS` — list of SSH key IDs in `[123456]` format
- `SERVERS_CONFIG` — HCL map of server configuration
- `OBJ_ACCESS_KEY` — same Object Storage access key used for the state bucket
- `OBJ_SECRET_KEY` — same Object Storage secret key used for the state bucket
- `OBJ_ENDPOINT` — Object Storage endpoint for the state bucket

Enable **Required reviewers** on the `production` environment to protect infrastructure apply operations.

### 4. Deploy via CI/CD

Push to `main`.

The build workflow:

1. Tests the application.
2. Builds an immutable Docker image tagged with the commit SHA.
3. Pushes the image to GHCR.
4. Deploys that specific image to the production server.

## Manual deployment without CI

Copy the repository to `/opt/gastro-api` on the server and create a `.env` file from `.env.example`.

Start the application:

```bash
cd /opt/gastro-api

docker compose --env-file .env pull
docker compose --env-file .env up -d
```

Start monitoring:

```bash
docker compose \
  --env-file .env \
  -f docker-compose.monitoring.yml \
  up -d
```

## Verification

Check container status:

```bash
docker compose --env-file .env ps
```

Check the public endpoint:

```bash
curl -I https://gastro.opik.net
curl https://gastro.opik.net/api/menu
```

Internal health checks are available inside the Docker network:

- `/health/live`
- `/health/ready`

The `/metrics` endpoint is not proxied publicly. Prometheus scrapes `api:8080/metrics` internally.

### Access Grafana and Prometheus

Grafana and Prometheus are bound to `127.0.0.1` on the host. Access them through an SSH tunnel:

```bash
ssh -L 3000:127.0.0.1:3000 deploy@YOUR_SERVER_IP
```

Then open:

`http://localhost:3000`

## Backups

### Enable the backup timer

```bash
sudo /usr/local/bin/gastro-install-systemd
systemctl list-timers gastro-backup.timer
```

### Create a manual backup

```bash
sudo /usr/local/bin/gastro-backup
```

### Restore a backup

```bash
sudo /opt/gastro-api/ops/backups/restore.sh \
  /path/to/postgres_YYYYMMDDTHHMMSSZ.dump
```

## Infrastructure management

Hetzner infrastructure is managed with OpenTofu.

The existing server, volume, and firewall are not recreated. They are imported into the OpenTofu state once, after which all changes are driven by code.

### Directory layout

```text
terraform/
├── live/
│   └── production/   # production environment configuration
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── imports.tf     # used ONLY for initial import, then removed
│       └── ...
└── modules/
    ├── server/
    ├── volume/
    └── firewall/
```

### Importing existing infrastructure

Obtain the real Hetzner resource IDs:

```bash
hcloud server list
hcloud firewall list
hcloud volume list
```

In `terraform/live/production/imports.tf`, uncomment the import blocks and insert the corresponding IDs.

Create a local `terraform.tfvars` file and do not commit it:

```hcl
hcloud_token = "..."
ssh_key_ids  = [123456]

servers = {
  gastro-prod = {
    server_name = "gastro-prod"
    server_type = "cx22"
    image       = "ubuntu-26.04"
    location    = "fsn1"
    volume_role = "postgres"
  }
}

volume_size = <actual volume size>
```

Set environment variables for Object Storage access:

```bash
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export OBJ_ENDPOINT=https://hel1.your-objectstorage.com
```

Run the import:

```bash
cd terraform/live/production

tofu init -backend-config="endpoint=$OBJ_ENDPOINT"
tofu plan   # Ensure there are no unexpected create/destroy operations.
tofu apply
```

After a successful apply:

1. Remove or comment out `imports.tf`.
2. Run `tofu plan` again and verify that it shows `No changes`.
3. Commit the infrastructure changes, including `.terraform.lock.hcl`.

## Daily operations

### Plan infrastructure changes

For a pull request:

```bash
tofu plan
```

### Apply infrastructure changes

Via CI after merge, or locally with caution:

```bash
tofu apply
```

### Add a second server

Configuration only, with no volume attached:

```hcl
servers = {
  gastro-prod = {
    # Existing production server configuration.
  }

  gastro-api-2 = {
    server_name = "gastro-api-2"
    server_type = "cx22"
    image       = "ubuntu-26.04"
    location    = "fsn1"
  }
}
```

### Retrieve server IPs

```bash
tofu output servers
```

### Important notes

- The PostgreSQL volume is attached only to the server with `volume_role = "postgres"`.
- `prevent_destroy = true` prevents accidental deletion of servers via OpenTofu.
- `delete_protection = true` on the volume adds an additional protection layer on the Hetzner side.
- S3 backend credentials are never stored in HCL files. Use environment variables or CI secrets.

## CI/CD workflows

- `build.yml` — builds, tests, and pushes a Docker image to GHCR.
- `deploy.yml` — deploys containers to the production server via SSH using the specific SHA tag.
- `infrastructure.yml` — runs on pull requests and executes `tofu plan`, formatting checks, and validation.
- `infrastructure-apply.yml` — runs on pushes to `main`, requires approval in the GitHub Environment, and applies infrastructure changes.

## Security notes

- Never commit `.env`, backend credentials, private SSH keys, or tokens.
- Only ports `80` and `443` for Caddy are publicly exposed.
- PostgreSQL, Prometheus, Grafana, Loki, and other internal services are accessible only inside the Docker network or via `localhost`.
- Docker published ports can bypass UFW rules. This stack publishes only Caddy's external ports.
- Do not enable volume formatting for an existing PostgreSQL volume unless you are certain it is empty. The existing production volume must never be reformatted.
