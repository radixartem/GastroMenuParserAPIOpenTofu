terraform {
  required_version = ">= 1.15.8, < 2.0.0"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.66.1"
    }
  }
}

provider "hcloud" { token = var.hcloud_token }

data "hcloud_server" "existing" { id = var.existing_server_id }
