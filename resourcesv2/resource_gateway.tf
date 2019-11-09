locals {
  gateway_hosts = {
    gateway-0 = {
      network = {
        store_ip         = "192.168.127.217"
        store_if         = "eth0"
        lan_ip           = "192.168.63.217"
        lan_if           = "eth1"
        sync_ip          = "192.168.190.1"
        sync_if          = "eth2"
        wan_if           = "eth3"
        wan_mac          = "52-54-00-63-6e-b2"
        vwan_if          = "eth4"
        vwan_mac         = "52-54-00-63-6e-b3"
        vwan_route_table = 250
        int_if           = "eth5"
        int_mac          = "52-54-00-1a-61-2a"
      }
      kea_ha_role = "primary"
    }
    gateway-1 = {
      network = {
        store_ip         = "192.168.127.218"
        store_if         = "eth0"
        lan_ip           = "192.168.63.218"
        lan_if           = "eth1"
        sync_ip          = "192.168.190.2"
        sync_if          = "eth2"
        wan_if           = "eth3"
        wan_mac          = "52-54-00-63-6e-b1"
        vwan_if          = "eth4"
        vwan_mac         = "52-54-00-63-6e-b3"
        vwan_route_table = 250
        int_if           = "eth5"
        int_mac          = "52-54-00-1a-61-2b"
      }
      kea_ha_role = "standby"
    }
  }
}

# Do this to each provider until for_each module is available
# module "gateway-0" {
#   source = "../modulesv2/gateway"

#   user              = local.user
#   mtu               = local.mtu
#   networks          = local.networks
#   services          = local.services
#   domains           = local.domains
#   container_images  = local.container_images
#   gateway_hosts     = local.gateway_hosts
#   ssh_ca_public_key = tls_private_key.ssh-ca.public_key_openssh

#   # Render to one of KVM host matchbox instances
#   renderer = local.renderers.kvm-0
# }

# module "gateway-1" {
#   source = "../modulesv2/gateway"

#   user              = local.user
#   mtu               = local.mtu
#   networks          = local.networks
#   services          = local.services
#   domains           = local.domains
#   container_images  = local.container_images
#   gateway_hosts     = local.gateway_hosts
#   ssh_ca_public_key = tls_private_key.ssh-ca.public_key_openssh

#   # Render to one of KVM host matchbox instances
#   renderer = local.renderers.kvm-1
# }

module "gateway-local" {
  source = "../modulesv2/gateway"

  user              = local.user
  mtu               = local.mtu
  networks          = local.networks
  services          = local.services
  domains           = local.domains
  container_images  = local.container_images
  gateway_hosts     = local.gateway_hosts
  ssh_ca_public_key = tls_private_key.ssh-ca.public_key_openssh

  renderer = local.local_renderer
}