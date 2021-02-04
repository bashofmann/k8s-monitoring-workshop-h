resource "hcloud_network" "net" {
  name = "private-net"
  ip_range = "10.0.0.0/8"
}

resource "hcloud_network_subnet" "subnet" {
  network_id = hcloud_network.net.id
  type = "cloud"
  network_zone = "eu-central"
  ip_range   = "10.0.1.0/24"
}

resource "hcloud_server" "node" {
  count = var.vm_count
  name = "monitoring-workshop-${count.index}"
  image = "ubuntu-20.04"
  server_type = "cx51"
  ssh_keys = [
    hcloud_ssh_key.workshop-key.name
  ]
}

resource "hcloud_server_network" "srvnetwork" {
  count = var.vm_count

  server_id = hcloud_server.node[count.index].id
  network_id = hcloud_network.net.id
}