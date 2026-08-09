output "servers" {
  description = "Provisioned servers with IPs"
  value = {
    for name, server in module.server :
    name => {
      id   = server.server_id
      ipv4 = server.ipv4_address
    }
  }
}

output "firewall_id" {
  value = module.firewall["production"].firewall_id
}

output "volume_id" {
  value = module.volume["postgres"].volume_id
}