variable "incusbr0_subnet" {
  description = "Subnet for the default Incus bridge"
  type        = string
  default     = "10.42.163.1/24"
}

variable "ovs_bridge_subnet_ipv4" {
  description = "IPv4 subnet for the OpenVSwitch bridge"
  type        = string
  default     = "10.193.26.1/24"
}

variable "ovs_bridge_subnet_ipv6" {
  description = "IPv6 subnet for the OpenVSwitch bridge"
  type        = string
  default     = "fd42:780b:d07c:5d2e::1/64"
}

variable "debian_image" {
  description = "Debian container image to use"
  type        = string
  default     = "images:debian/trixie"
}

variable "alpine_image" {
  description = "Alpine container image to use"
  type        = string
  default     = "images:alpine/3.22"
}

variable "server_vlan" {
  description = "VLAN ID for server network"
  type        = string
  default     = "2"
}

variable "remote_vlan" {
  description = "VLAN ID for remote network"
  type        = string
  default     = "3"
}

variable "router_vlan" {
  description = "VLAN ID for router-to-router network"
  type        = string
  default     = "4"
}