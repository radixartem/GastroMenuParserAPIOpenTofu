resource "hcloud_volume" "this" {
  name              = var.volume_name
  size              = var.size
  location          = var.location
  delete_protection = var.delete_protection

  labels = merge(
    var.labels,
    {
      managed-by = "opentofu"
    }
  )
}