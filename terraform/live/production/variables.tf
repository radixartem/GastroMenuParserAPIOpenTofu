variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "existing_server_id" {
  type        = number
  description = "Existing Hetzner Cloud server ID. Terraform reads it but does not manage or destroy the server."
}

variable "existing_firewall_id" {
  type        = number
  default     = null
  description = "Optional existing Hetzner Firewall ID."
}

variable "existing_volume_id" {
  type        = number
  default     = null
  description = "Optional existing Hetzner Volume ID used for PostgreSQL."
}

variable "project_name" {
  type    = string
  default = "gastro"
}

variable "environment" {
  type    = string
  default = "production"
}
