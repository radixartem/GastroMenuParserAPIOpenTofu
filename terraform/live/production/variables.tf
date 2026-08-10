variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "ssh_key_ids" {
  description = "List of SSH key IDs"
  type        = list(number)
  default     = []
}

variable "servers" {
  description = "Server configurations"
  type = map(object({
    server_name = string
    server_type = string
    image       = string
    location    = string
  }))
  default = {}
}

variable "environment" {
  type    = string
  default = "production"
}