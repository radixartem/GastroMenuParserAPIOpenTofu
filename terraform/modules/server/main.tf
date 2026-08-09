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
  }
}

resource "hcloud_volume_attachment" "this" {
  count = var.volume_id != null ? 1 : 0

  server_id = hcloud_server.this.id
  volume_id = var.volume_id
  # automount оставлен по умолчанию (false), чтобы не менять поведение существующего сервера при импорте
}