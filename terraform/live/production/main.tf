locals {
  postgres_server_location = var.servers[var.postgres_server].location
}

# ── Firewall ──────────────────────────────────────────────
module "firewall" {
  source = "../../modules/firewall"
  for_each = {
    production = {
      name  = var.firewall_name
      rules = var.firewall_rules
    }
  }

  firewall_name = each.value.name
  rules         = each.value.rules
  labels = {
    environment = var.environment
    managed-by  = "opentofu"
  }
}

# ── Volume ────────────────────────────────────────────────
module "volume" {
  source = "../../modules/volume"
  for_each = {
    postgres = {
      name = var.volume_name
      size = var.volume_size
    }
  }

  volume_name       = each.value.name
  size              = each.value.size
  location          = local.postgres_server_location
  delete_protection = true

  labels = {
    environment = var.environment
    managed-by  = "opentofu"
  }
}

# ── Servers ───────────────────────────────────────────────
module "server" {
  source   = "../../modules/server"
  for_each = var.servers

  server_name = each.value.server_name
  server_type = each.value.server_type
  image       = each.value.image
  location    = each.value.location

  ssh_key_ids  = var.ssh_key_ids
  firewall_ids = [module.firewall["production"].firewall_id]

  volume_id = (
    each.value.volume_role == "postgres"
    ? module.volume["postgres"].volume_id
    : null
  )

  prevent_destroy = true
  environment     = var.environment

  labels = {
    application = "gastro-menu-parser"
  }
}