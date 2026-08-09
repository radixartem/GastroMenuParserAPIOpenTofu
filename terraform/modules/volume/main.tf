resource "hcloud_volume" "this" {
  name = var.volume_name
  size = var.size_gb
  location = var.location
  format = var.format
  lifecycle { prevent_destroy = true }
}
