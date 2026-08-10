variable "firewall_name" {
  type = string
}

variable "rules" {
  type = list(object({
    direction  = string
    protocol   = string
    port       = string
    source_ips = list(string)
  }))
}

variable "labels" {
  type    = map(string)
  default = {}
}