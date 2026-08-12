# GastroMenuParserAPI

Production-ready ASP.NET Core API for importing and storing menu data from `essen-auf-raedern-eichsfeld.de`.

The repository contains the complete application and production platform: PostgreSQL, Docker Compose, Caddy, Prometheus, Grafana, Loki, Grafana Alloy, OpenTofu, Ansible, GitHub Actions, GHCR, and S3-compatible backups.

## Architecture

```text
                         ┌──────────────────────┐
                         │      GitHub          │
                         │  Source + Actions    │
                         └──────────┬───────────┘
                                    │
                         test / build / publish
                                    │
                                    ▼
                         ┌──────────────────────┐
                         │        GHCR          │
                         │ Immutable SHA images │
                         └──────────┬───────────┘
                                    │
                               SSH deploy
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Hetzner Cloud / Production                   │
│                                                                 │
│  Internet ──► :80/:443 ──► Caddy ──► ASP.NET Core API          │
│                                      │                          │
│                                      ├──► PostgreSQL 16         │
│                                      │     persistent storage   │
│                                      │                          │
│                                      └──► /metrics              │
│                                             │                   │
│                    Prometheus ◄─────────────┘                   │
│                         │                                       │
│                         ├──► Grafana                            │
│                         └──► Loki / Grafana Alloy               │
│                                                                 │
│  OpenTofu: infrastructure │ Ansible: server bootstrap           │
│  Backups: PostgreSQL ──► S3-compatible Object Storage           │
└─────────────────────────────────────────────────────────────────┘
```

## Features

- Import menu data from the configured public website.
- Persist imported data in PostgreSQL 16.
- Run the application in Docker Compose.
- Serve HTTPS traffic through Caddy.
- Expose liveness and readiness health checks.
- Export internal Prometheus metrics.
- Collect logs with Grafana Alloy and Loki.
- Visualize metrics and logs with Grafana.
- Build immutable container images tagged with the Git commit SHA.
- Publish images to GitHub Container Registry (GHCR).
- Deploy production containers through GitHub Actions and SSH.
- Manage Hetzner infrastructure with OpenTofu.
- Bootstrap and configure servers with Ansible.
- Store backups in S3-compatible Hetzner Object Storage.

## Technology stack

| Area | Technology |
|---|---|
| OS | Ubuntu 26.04 LTS |
| Runtime | .NET 10 / ASP.NET Core 10 |
| Database | PostgreSQL 16 |
| Containers | Docker Engine + Docker Compose V2 |
| Reverse proxy | Caddy 2 |
| Metrics | Prometheus |
| Dashboards | Grafana |
| Logs | Loki + Grafana Alloy |
| CI/CD | GitHub Actions |
| Container registry | GHCR |
| Infrastructure as Code | OpenTofu |
| Configuration management | Ansible |
| Cloud provider | Hetzner Cloud |
| Backups | S3-compatible Object Storage |

## Repository structure

```text
.
├── .github/
│   └── workflows/                 # CI/CD and infrastructure workflows
├── caddy/                         # Caddy configuration
├── ops/
│   ├── ansible/                   # Server bootstrap and configuration
│   └── backups/                   # Backup and restore scripts
├── src/
│   └── GastroLeinefeldeAPI/       # ASP.NET Core application
├── terraform/
│   ├── live/
│   │   └── production/            # Production OpenTofu configuration
│   └── modules/                   # Reusable infrastructure modules
├── .env.example                   # Environment variable template
├── DEPLOYMENT.md                  # Detailed production deployment runbook
├── GastroLeinefeldeAPI.slnx       # .NET solution
├── docker-compose.yml             # Main application stack
├── docker-compose.dev.yml         # Development configuration
├── docker-compose.monitoring.yml  # Monitoring stack
├── docker-compose.override.yml    # Local overrides
└── global.json                    # .NET SDK selection
```

## Prerequisites

### Local development

Install:

- .NET SDK required by `global.json`
- Docker Engine
- Docker Compose V2
- Git

### Production infrastructure

Install locally or use CI:

- OpenTofu
- Hetzner Cloud CLI (`hcloud`) for inspecting/importing existing resources
- Ansible
- Required Ansible collections from `ops/ansible/requirements.yml`

The production server should run Ubuntu 26.04 LTS.

## Quick start

Clone the repository:

```bash
git clone https://github.com/radixartem/GastroMenuParserAPIOpenTofu.git
cd GastroMenuParserAPIOpenTofu
```

Create a local environment file:

```bash
cp .env.example .env
```

Review and set all required values in `.env`.

Start the application stack:

```bash
docker compose --env-file .env up --build -d
```

Check status:

```bash
docker compose --env-file .env ps
```

View logs:

```bash
docker compose --env-file .env logs -f
```

Stop the stack:

```bash
docker compose --env-file .env down
```

> Do not commit `.env`.

## Local .NET development

Restore dependencies:

```bash
dotnet restore GastroLeinefeldeAPI.slnx
```

Build:

```bash
dotnet build GastroLeinefeldeAPI.slnx --no-restore
```

Run tests when tests are present:

```bash
dotnet test GastroLeinefeldeAPI.slnx --no-build
```

Run the API directly from the application project:

```bash
cd src/GastroLeinefeldeAPI
dotnet run
```

For development with Docker, use the repository's development Compose configuration:

```bash
docker compose \
  --env-file .env \
  -f docker-compose.yml \
  -f docker-compose.dev.yml \
  up --build
```

## Environment configuration

Use `.env.example` as the canonical starting point:

```bash
cp .env.example .env
```

Typical production configuration includes values for:

| Variable group | Purpose |
|---|---|
| PostgreSQL | Database credentials and connection settings |
| API | Application secrets and import API key |
| Caddy | Public hostname and ACME/Let's Encrypt email |
| Grafana | Initial administrator credentials |
| GHCR | Registry image and deployment credentials |
| Object Storage | Backup endpoint, bucket, access key, secret key |

Never store real secrets in:

- `README.md`
- `terraform.tfvars` committed to Git
- workflow YAML
- Docker Compose files
- source code

Use GitHub Secrets, GitHub Environments, local `.env` files, or protected environment variables.

## Production deployment

The recommended deployment flow is:

1. Provision or import infrastructure with OpenTofu.
2. Bootstrap the server with Ansible.
3. Configure DNS.
4. Configure the GitHub `production` Environment and secrets.
5. Push application changes to `main`.
6. GitHub Actions tests and builds the application.
7. The image is published to GHCR with an immutable SHA tag.
8. The deployment workflow pulls that exact image to production.
9. Docker Compose starts the updated services.
10. Health checks verify the deployment.

For detailed operational instructions, see `DEPLOYMENT.md`.

## DNS and HTTPS

Configure the DNS record for the production hostname so that it points to the production server.

Example:

```text
gastro.opik.net  →  PRODUCTION_SERVER_IP
```

Caddy handles reverse proxying and automatic HTTPS certificate management.

Before enabling HTTPS, verify that:

- the DNS record resolves to the production server;
- ports `80` and `443` are reachable from the Internet;
- the firewall allows the required HTTP/HTTPS traffic.

## Server bootstrap with Ansible

Install required collections:

```bash
ansible-galaxy collection install -r ops/ansible/requirements.yml
```

Set the production server IP:

```bash
export PRODUCTION_IP=YOUR_SERVER_IP
```

Run the bootstrap playbook:

```bash
ansible-playbook \
  -i ops/ansible/inventory/hosts.yml \
  ops/ansible/playbooks/bootstrap.yml
```

The bootstrap process is responsible for preparing the server according to the repository's Ansible configuration.

## GitHub Actions and GHCR

The CI/CD design uses immutable images.

A successful build produces an image identified by the Git commit SHA. Production deployment should use that exact SHA rather than a mutable `latest` tag.

The workflow set includes:

- `build.yml` — restore/build/test and publish the application image to GHCR.
- `deploy.yml` — deploy a specific SHA-tagged image to production through SSH.
- `infrastructure.yml` — OpenTofu formatting, validation, and planning.
- `infrastructure-apply.yml` — approved production infrastructure changes.

The repository also uses GitHub Environments to protect sensitive production operations.

## GitHub production secrets

Create a GitHub Environment named:

```text
production
```

Recommended secrets include the following.

### Application deployment

- `PROD_SERVER_IP`
- `PROD_DEPLOY_USER`
- `PROD_SSH_KEY`
- `PROD_KNOWN_HOSTS`
- `PROD_POSTGRES_PASSWORD`
- `PROD_GRAFANA_PASSWORD`
- `PROD_IMPORT_API_KEY`
- `GHCR_USERNAME`
- `GHCR_READ_TOKEN`
- `GHCR_PUSH_TOKEN` if required by the configured image publishing workflow
- `ACME_EMAIL`
- `OBJ_ACCESS_KEY`
- `OBJ_SECRET_KEY`
- `OBJ_ENDPOINT`
- `OBJ_BUCKET`

### Infrastructure

- `HCLOUD_TOKEN`
- `SSH_KEY_IDS`
- `SERVERS_CONFIG`
- Object Storage credentials required by the configured OpenTofu state backend

The exact secret names must match the workflow YAML in `.github/workflows/`.

Enable **Required reviewers** for the `production` Environment if infrastructure or deployment approval is required.

## Manual production deployment

Automatic deployment through GitHub Actions is recommended.

For a manual deployment, copy or clone the repository to the production server:

```bash
cd /opt
git clone https://github.com/radixartem/GastroMenuParserAPIOpenTofu.git gastro-api
cd gastro-api
```

Create the production environment file:

```bash
cp .env.example .env
chmod 600 .env
```

Populate `.env` with production values.

Pull the configured application image and start the stack:

```bash
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

Verify:

```bash
docker compose --env-file .env ps
```

## Health checks and metrics

The API provides internal health endpoints:

- `/health/live` — liveness
- `/health/ready` — readiness

The metrics endpoint is:

```text
/metrics
```

Metrics should not be exposed publicly. Prometheus scrapes the API through the internal Docker network, for example:

```text
api:8080/metrics
```

Check the public API:

```bash
curl -I https://gastro.opik.net
curl https://gastro.opik.net/api/menu
```

Adjust the hostname if your production environment uses a different domain.

## Monitoring

The observability stack contains:

```text
API
 │
 ├── metrics ──► Prometheus ──► Grafana
 │
 └── logs ────► Grafana Alloy ──► Loki ──► Grafana
```

Start the monitoring stack:

```bash
docker compose \
  --env-file .env \
  -f docker-compose.monitoring.yml \
  up -d
```

Check monitoring containers:

```bash
docker compose \
  --env-file .env \
  -f docker-compose.monitoring.yml \
  ps
```

Grafana and Prometheus should be bound to localhost where configured, rather than exposed publicly.

Example Grafana SSH tunnel:

```bash
ssh -L 3000:127.0.0.1:3000 deploy@YOUR_SERVER_IP
```

Then open:

```text
http://localhost:3000
```

If Prometheus is also mapped to localhost, create a separate tunnel using its configured host port.

## Backups

Backups are stored in S3-compatible Hetzner Object Storage.

The backup configuration uses credentials and endpoint values supplied through protected environment variables.

Enable the backup timer:

```bash
sudo /usr/local/bin/gastro-install-systemd
systemctl list-timers gastro-backup.timer
```

Run a backup manually:

```bash
sudo /usr/local/bin/gastro-backup
```

Inspect the service and timer:

```bash
systemctl status gastro-backup.service
systemctl status gastro-backup.timer
```

### Restore

Restore using the repository restore script:

```bash
sudo /opt/gastro-api/ops/backups/restore.sh \
  /path/to/postgres_YYYYMMDDTHHMMSSZ.dump
```

Before restoring production data:

1. Stop or isolate writers.
2. Verify the backup file and timestamp.
3. Confirm the target database.
4. Ensure you understand whether the restore replaces existing data.
5. Perform a test restore in a non-production environment whenever possible.

## Infrastructure management with OpenTofu

OpenTofu manages Hetzner infrastructure through the configuration under:

```text
terraform/
├── live/
│   └── production/
└── modules/
```

The production configuration is the source of truth for resources managed by OpenTofu.

### Initialize

Set the credentials required by the configured backend. For S3-compatible backends, credentials should normally be provided through environment variables rather than committed HCL.

Example:

```bash
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export OBJ_ENDPOINT=https://YOUR_OBJECT_STORAGE_ENDPOINT
```

Initialize:

```bash
cd terraform/live/production

tofu init -backend-config="endpoint=$OBJ_ENDPOINT"
```

Validate:

```bash
tofu fmt -check -recursive
tofu validate
```

Plan:

```bash
tofu plan
```

Apply only after reviewing the plan:

```bash
tofu apply
```

### Existing infrastructure

If the production server, volume, or firewall already exists, import it according to the actual OpenTofu configuration before allowing routine applies.

First obtain real Hetzner IDs:

```bash
hcloud server list
hcloud firewall list
hcloud volume list
```

Then use the import mechanism defined by the production configuration.

Before applying changes, verify that the plan does not unexpectedly recreate production resources.

After import, run:

```bash
tofu plan
```

The expected steady state is:

```text
No changes.
```

Commit `.terraform.lock.hcl` when generated or updated, but never commit backend credentials or private secrets.

## OpenTofu state and security

The state backend may contain sensitive infrastructure metadata.

Rules:

- Do not commit backend access keys.
- Do not commit Object Storage secret keys.
- Do not expose `terraform.tfstate` publicly.
- Use CI secrets or protected environment variables.
- Restrict access to the state bucket.
- Enable versioning or retention when supported by the storage design.
- Review every production plan before apply.

## Adding infrastructure

Define additional infrastructure in the existing production configuration and reusable modules rather than creating unmanaged resources manually.

A conceptual second server configuration may look like:

```hcl
servers = {
  gastro-prod = {
    server_name = "gastro-prod"
    server_type = "cx22"
    image       = "ubuntu-26.04"
    location    = "fsn1"
  }

  gastro-api-2 = {
    server_name = "gastro-api-2"
    server_type = "cx22"
    image       = "ubuntu-26.04"
    location    = "fsn1"
  }
}
```

Use the exact variable schema implemented in `terraform/live/production/variables.tf`.

Retrieve outputs:

```bash
tofu output
```

For server output specifically, if defined:

```bash
tofu output servers
```

## Docker operations

### Status

```bash
docker compose --env-file .env ps
```

### Application logs

```bash
docker compose --env-file .env logs -f
```

### API logs

```bash
docker compose --env-file .env logs -f api
```

### PostgreSQL logs

```bash
docker compose --env-file .env logs -f postgres
```

### Restart

```bash
docker compose --env-file .env restart
```

### Pull and recreate

```bash
docker compose --env-file .env pull
docker compose --env-file .env up -d
```

### Stop

```bash
docker compose --env-file .env down
```

Do not add `-v` to `docker compose down` in production unless you explicitly intend to remove named volumes.

## Security model

The production deployment should follow these principles:

- Only Caddy publishes public HTTP/HTTPS ports.
- PostgreSQL is not publicly exposed.
- Prometheus, Loki, Grafana, and internal metrics are not publicly exposed.
- Internal services communicate through Docker networks.
- Secrets are stored outside the repository.
- Production deployment uses SSH keys rather than passwords.
- SSH host verification uses a known-hosts entry.
- Container images are pinned to immutable Git SHA tags.
- Production infrastructure changes are reviewed before apply.
- Existing database volumes must never be reformatted accidentally.
- Destructive OpenTofu changes must be reviewed carefully.
- Docker-published ports can bypass some host firewall expectations; publish only ports that are intentionally required.

## Troubleshooting

### Containers do not start

Inspect status:

```bash
docker compose --env-file .env ps
```

Inspect logs:

```bash
docker compose --env-file .env logs --tail=200
```

### API cannot connect to PostgreSQL

Check PostgreSQL:

```bash
docker compose --env-file .env logs postgres
```

Verify:

- database container health;
- PostgreSQL environment variables;
- application connection string;
- Docker network connectivity.

### Deployment cannot pull from GHCR

Verify:

- the image name configured in `.env` and workflows;
- the requested SHA tag exists;
- the registry username is correct;
- the token has the required `read:packages` permission;
- the production host can authenticate to GHCR.

### HTTPS certificate is not issued

Verify:

```bash
dig +short gastro.opik.net
```

The result must be the production server IP.

Also verify that ports `80` and `443` are reachable.

Check Caddy logs:

```bash
docker compose --env-file .env logs caddy
```

### OpenTofu wants to recreate an existing production resource

Stop and investigate.

Run:

```bash
tofu plan
```

Check resource addresses, IDs, imports, and module paths. Do not apply until the plan matches the intended production state.

### Backup fails

Check:

```bash
systemctl status gastro-backup.service
journalctl -u gastro-backup.service --no-pager -n 200
```

Verify Object Storage:

- endpoint;
- bucket;
- access key;
- secret key;
- network connectivity;
- permissions.

## Deployment checklist

- [ ] DNS points to the production server.
- [ ] Ports `80` and `443` are reachable.
- [ ] OpenTofu state backend is configured securely.
- [ ] Existing Hetzner resources are imported if necessary.
- [ ] `tofu plan` has been reviewed.
- [ ] Ansible bootstrap completed successfully.
- [ ] Production `.env` exists and is not committed.
- [ ] PostgreSQL password is configured.
- [ ] Import API key is configured.
- [ ] Grafana password is configured.
- [ ] GHCR credentials are configured.
- [ ] Object Storage credentials are configured.
- [ ] GitHub `production` Environment exists.
- [ ] Required GitHub secrets match workflow names.
- [ ] Production deployment approval is configured if required.
- [ ] Application image is built successfully.
- [ ] Production deployment completed successfully.
- [ ] Health endpoints are responding.
- [ ] HTTPS is working.
- [ ] Prometheus is scraping metrics.
- [ ] Grafana is accessible through a secure tunnel.
- [ ] Backup timer is active.
- [ ] A backup has been tested.
- [ ] Restore procedure has been validated.

## Documentation

- `README.md` — project overview and operational quick reference.
- `DEPLOYMENT.md` — detailed deployment runbook.
- `.env.example` — environment variable template.
- `terraform/live/production/` — production infrastructure source of truth.
- `ops/ansible/` — server configuration and bootstrap automation.
- `.github/workflows/` — CI/CD and infrastructure automation.

## License

MIT
