output "node_ips" {
  value = hcloud_server.node.*.ipv4_address
}