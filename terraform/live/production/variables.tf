variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "ssh_key_ids" {
  description = "List of SSH key IDs"
  type        = list(number)
}

variable "servers" {
  description = "Server configurations"
  type = map(object({
    server_name = string
    server_type = string
    image       = string
    location    = string
    volume_role = optional(string, null)   # "postgres" – к этому серверу подключается PostgreSQL-том
  }))
  default = {}
}

variable "firewall_name" {
  type    = string
  default = "gastro-prod-firewall"
}

variable "firewall_rules" {
  description = "Firewall rules"
  type = list(object({
    direction  = string
    protocol   = string
    port       = string
    source_ips = list(string)
  }))
  default = [
    {
      direction  = "in"
      protocol   = "tcp"
      port       = "22"
      source_ips = ["0.0.0.0/0"]
    },
    {
      direction  = "in"
      protocol   = "tcp"
      port       = "80"
      source_ips = ["0.0.0.0/0"]
    },
    {
      direction  = "in"
      protocol   = "tcp"
      port       = "443"
      source_ips = ["0.0.0.0/0"]
    }
  ]
}

variable "volume_name" {
  type    = string
  default = "gastro-postgres-data"
}

variable "volume_size" {
  type    = number
  default = 20
}

variable "postgres_server" {
  description = "Ключ сервера в var.servers, к которому подключается PostgreSQL-том"
  type        = string
  default     = "gastro-prod"

  validation {
    condition     = contains(keys(var.servers), var.postgres_server)
    error_message = "postgres_server должен быть одним из ключей var.servers."
  }
}

variable "environment" {
  type    = string
  default = "production"
}