resource "hcloud_firewall" "this" {
  name = var.firewall_name

  dynamic "rule" {
    for_each = var.rules
    content {
      direction  = rule.value.direction
      protocol   = rule.value.protocol
      port       = rule.value.port
      source_ips = rule.value.source_ips
    }
  }

  lifecycle { prevent_destroy = true }
}
