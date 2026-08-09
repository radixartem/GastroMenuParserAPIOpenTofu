output "server_id" {
  value = data.hcloud_server.production.id
}

output "server_name" {
  value = data.hcloud_server.production.name
}

output "server_ipv4" {
  value = data.hcloud_server.production.ipv4_address
}

output "server_location" {
  value = data.hcloud_server.production.location
}

output "firewall_id" {
  value = var.existing_firewall_id
}

output "postgres_volume_id" {
  value     = var.existing_volume_id
  sensitive = true
}
