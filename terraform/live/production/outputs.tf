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