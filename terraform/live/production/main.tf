terraform {
  required_version = ">= 1.15.8, < 2.0.0"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.66.1"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

data "hcloud_server" "production" {
  id = var.existing_server_id
}

data "hcloud_firewall" "production" {
  count = var.existing_firewall_id == null ? 0 : 1
  id    = var.existing_firewall_id
}

data "hcloud_volume" "postgres" {
  count = var.existing_volume_id == null ? 0 : 1
  id    = var.existing_volume_id
}

locals {
  server = data.hcloud_server.production
}
