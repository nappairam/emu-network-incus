output "core_router_ip_addresses" {
  description = "IP addresses of the core-router container"
  value = {
    eth0 = incus_instance.core_router.ipv4_address
    name = incus_instance.core_router.name
  }
}

output "server_ip_addresses" {
  description = "IP addresses of the server container"
  value = {
    eth0 = incus_instance.server.ipv4_address
    name = incus_instance.server.name
  }
}

output "remote_ip_addresses" {
  description = "IP addresses of the remote container"
  value = {
    eth0 = incus_instance.remote.ipv4_address
    name = incus_instance.remote.name
  }
}

output "core_router_2_ip_addresses" {
  description = "IP addresses of the core-router-2 container"
  value = {
    eth0 = incus_instance.core_router_2.ipv4_address
    name = incus_instance.core_router_2.name
  }
}

output "network_info" {
  description = "Network configuration information"
  value = {
    incusbr0_config    = incus_network.incusbr0.config
    net_ovsbr0_config  = incus_network.net_ovsbr0.config
  }
}