# Production Terraform

This environment is intentionally **read-only with respect to the existing server**. It uses `data "hcloud_server"` so running `terraform apply` cannot recreate or destroy the existing production server.

Configure the S3 backend endpoint and credentials, then:

```bash
terraform init -backend-config=backend.hcl
terraform plan
```

Required backend environment  variables:

```bash
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
```

Create `backend.hcl` locally from `backend.hcl.example`.
