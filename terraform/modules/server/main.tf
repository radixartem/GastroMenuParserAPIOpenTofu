resource "hcloud_server" "this" {
  name        = var.server_name
  server_type = var.server_type
  image       = var.image
  location    = var.location

  ssh_keys     = var.ssh_key_ids
  user_data    = var.user_data
  firewall_ids = var.firewall_ids

  labels = merge(
    var.labels,
    {
      managed-by  = "opentofu"
      environment = var.environment
    }
  )

  lifecycle {
    prevent_destroy = var.prevent_destroy
    ignore_changes  = [user_data]  
  }
}