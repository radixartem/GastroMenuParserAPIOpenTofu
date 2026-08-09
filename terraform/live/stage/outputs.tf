output "server_id" { value = data.hcloud_server.existing.id }
output "server_ipv4" { value = data.hcloud_server.existing.ipv4_address }
