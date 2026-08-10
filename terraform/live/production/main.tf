module "server" {
  source   = "../../modules/server"
  for_each = var.servers

  server_name   = each.value.server_name
  server_type   = each.value.server_type
  image         = each.value.image
  location      = each.value.location
  ssh_key_ids   = var.ssh_key_ids
  firewall_ids  = []
  volume_id     = null

  prevent_destroy = true
  environment     = var.environment

  labels = {
    application = "gastro-menu-parser"
  }
}