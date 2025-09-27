terraform {
  required_version = ">= 1.0"
  required_providers {
    incus = {
      source  = "lxc/incus"
      version = "~> 0.1.0"
    }
  }
}

provider "incus" {}

# Networks
resource "incus_network" "incusbr0" {
  name = "incusbr0"
  type = "bridge"
  config = {
    "ipv4.address" = "10.42.163.1/24"
    "ipv4.nat"     = "true"
  }
}

resource "incus_network" "net_ovsbr0" {
  name = "net-ovsbr0"
  type = "bridge"
  config = {
    "bridge.driver" = "openvswitch"
    "ipv4.address"  = "10.193.26.1/24"
    "ipv4.nat"      = "true"
    "ipv6.address"  = "fd42:780b:d07c:5d2e::1/64"
    "ipv6.nat"      = "true"
  }
}

# Profiles
resource "incus_profile" "prf_router_server" {
  name = "prf-router-server"

  device {
    name = "eth2"
    type = "nic"
    properties = {
      name     = "eth2"
      nictype  = "bridged"
      parent   = incus_network.net_ovsbr0.name
      vlan     = "2"
    }
  }
}

resource "incus_profile" "prf_router_remote" {
  name = "prf-router-remote"

  device {
    name = "eth3"
    type = "nic"
    properties = {
      name     = "eth3"
      nictype  = "bridged"
      parent   = incus_network.net_ovsbr0.name
      vlan     = "3"
    }
  }
}

resource "incus_profile" "prf_router_router" {
  name = "prf-router-router"

  device {
    name = "eth4"
    type = "nic"
    properties = {
      name     = "eth4"
      nictype  = "bridged"
      parent   = incus_network.net_ovsbr0.name
      vlan     = "4"
    }
  }
}

# Containers
resource "incus_instance" "core_router" {
  name  = "core-router"
  image = "images:debian/trixie"
  type  = "container"

  profiles = [
    "default",
    incus_profile.prf_router_server.name,
    incus_profile.prf_router_remote.name,
    incus_profile.prf_router_router.name,
  ]

  config = {
    "boot.autostart" = "true"
  }

  file {
    content             = file("${path.module}/configs/core-router/eth0.network")
    target_path         = "/etc/systemd/network/eth0.network"
    mode                = "0644"
    create_directories  = true
  }

  file {
    content             = file("${path.module}/configs/core-router/eth2.network")
    target_path         = "/etc/systemd/network/eth2.network"
    mode                = "0644"
    create_directories  = true
  }

  file {
    content             = file("${path.module}/configs/core-router/eth3.network")
    target_path         = "/etc/systemd/network/eth3.network"
    mode                = "0644"
    create_directories  = true
  }

  file {
    content             = file("${path.module}/configs/core-router/lo.network")
    target_path         = "/etc/systemd/network/lo.network"
    mode                = "0644"
    create_directories  = true
  }
}

resource "incus_instance" "server" {
  name  = "server"
  image = "images:debian/trixie"
  type  = "container"

  profiles = [
    "default",
    incus_profile.prf_router_server.name,
  ]

  config = {
    "boot.autostart" = "true"
  }

  file {
    content             = file("${path.module}/configs/server/eth0.network")
    target_path         = "/etc/systemd/network/eth0.network"
    mode                = "0644"
    create_directories  = true
  }

  file {
    content             = file("${path.module}/configs/server/eth2.network")
    target_path         = "/etc/systemd/network/eth2.network"
    mode                = "0644"
    create_directories  = true
  }

  file {
    content             = file("${path.module}/configs/server/lo.network")
    target_path         = "/etc/systemd/network/lo.network"
    mode                = "0644"
    create_directories  = true
  }
}

resource "incus_instance" "remote" {
  name  = "remote"
  image = "images:alpine/3.22"
  type  = "container"

  profiles = [
    "default",
    incus_profile.prf_router_remote.name,
  ]

  config = {
    "boot.autostart" = "true"
  }

  file {
    content             = file("${path.module}/configs/remote/interfaces")
    target_path         = "/etc/network/interfaces"
    mode                = "0644"
    create_directories  = true
  }
}

resource "incus_instance" "core_router_2" {
  name  = "core-router-2"
  image = "images:debian/trixie"
  type  = "container"

  profiles = [
    "default",
    incus_profile.prf_router_router.name,
  ]

  config = {
    "boot.autostart" = "true"
  }

  file {
    content             = file("${path.module}/configs/core-router-2/eth0.network")
    target_path         = "/etc/systemd/network/eth0.network"
    mode                = "0644"
    create_directories  = true
  }
}
