module "kubernetes-common" {
  source = "../modulesv2/kubernetes_common"

  cluster_name          = "default-cluster-012"
  s3_backup_aws_region  = "us-west-2"
  s3_etcd_backup_bucket = "randomcoww-etcd-backup"

  user              = local.user
  ssh_ca_public_key = tls_private_key.ssh-ca.public_key_openssh
  mtu               = local.mtu
  networks          = local.networks
  services          = local.services
  domains           = local.domains
  container_images  = local.container_images

  controller_hosts = {
    controller-0 = {
      network = {
        store_ip = "192.168.127.219"
        store_if = "eth0"
        int_if   = "eth1"
        int_mac  = "52-54-00-1a-61-0a"
      }
    }
    controller-1 = {
      network = {
        store_ip = "192.168.127.220"
        store_if = "eth0"
        int_if   = "eth1"
        int_mac  = "52-54-00-1a-61-0b"
      }
    }
    controller-2 = {
      network = {
        store_ip = "192.168.127.221"
        store_if = "eth0"
        int_if   = "eth1"
        int_mac  = "52-54-00-1a-61-0c"
      }
    }
  }
  worker_hosts = {
    worker-0 = {
      network = {
        store_if = "eth0"
        int_if   = "eth1"
        int_mac  = "52-54-00-1a-61-1a"
      }
      disks = {
        "S4PGNF0M414895K" = {
          device     = "/dev/vda"
          format     = "ext4"
          mount_path = "/pv"
        }
        "2YK7XTRD" = {
          device     = "/dev/disk/by-id/ata-WDC_WD100EFAX-68LHPN0_2YK7XTRD"
          format     = "xfs"
          mount_path = "/minio/0"
        }
        "2YK87AVD" = {
          device     = "/dev/disk/by-id/ata-WDC_WD100EFAX-68LHPN0_2YK87AVD"
          format     = "xfs"
          mount_path = "/minio/1"
        }
        "2YK89PND" = {
          device     = "/dev/disk/by-id/ata-WDC_WD100EFAX-68LHPN0_2YK89PND"
          format     = "xfs"
          mount_path = "/minio/2"
        }
        "2YKG1X2D" = {
          device     = "/dev/disk/by-id/ata-WDC_WD100EFAX-68LHPN0_2YKG1X2D"
          format     = "xfs"
          mount_path = "/minio/3"
        }
        "2YKGML5D" = {
          device     = "/dev/disk/by-id/ata-WDC_WD100EFAX-68LHPN0_2YKGML5D"
          format     = "xfs"
          mount_path = "/minio/4"
        }
        "2YKGML7D" = {
          device     = "/dev/disk/by-id/ata-WDC_WD100EFAX-68LHPN0_2YKGML7D"
          format     = "xfs"
          mount_path = "/minio/5"
        }
        "2YKGNL4D" = {
          device     = "/dev/disk/by-id/ata-WDC_WD100EFAX-68LHPN0_2YKGNL4D"
          format     = "xfs"
          mount_path = "/minio/6"
        }
        "JEK830AZ" = {
          device     = "/dev/disk/by-id/ata-WDC_WD100EFAX-68LHPN0_JEK830AZ"
          format     = "xfs"
          mount_path = "/minio/7"
        }
        "JEK830RZ" = {
          device     = "/dev/disk/by-id/ata-WDC_WD100EFAX-68LHPN0_JEK830RZ"
          format     = "xfs"
          mount_path = "/minio/8"
        }
        "JEK8V1YZ" = {
          device     = "/dev/disk/by-id/ata-WDC_WD100EFAX-68LHPN0_JEK8V1YZ"
          format     = "xfs"
          mount_path = "/minio/9"
        }
        "JEK8YTSZ" = {
          device     = "/dev/disk/by-id/ata-WDC_WD100EFAX-68LHPN0_JEK8YTSZ"
          format     = "xfs"
          mount_path = "/minio/10"
        }
        "JEKAZ92N" = {
          device     = "/dev/disk/by-id/ata-WDC_WD100EFAX-68LHPN0_JEKAZ92N"
          format     = "xfs"
          mount_path = "/minio/11"
        }
      }
    }
    worker-1 = {
      network = {
        store_if = "eth0"
        int_if   = "eth1"
        int_mac  = "52-54-00-1a-61-1b"
      }
      disks = {
        "S4PGNF0M410395Z" = {
          device     = "/dev/vda"
          format     = "ext4"
          mount_path = "/pv"
        }
      }
    }
  }
}

module "gateway-common" {
  source = "../modulesv2/gateway_common"

  user              = local.user
  ssh_ca_public_key = tls_private_key.ssh-ca.public_key_openssh
  mtu               = local.mtu
  networks          = local.networks
  services          = local.services
  domains           = local.domains
  container_images  = local.container_images

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

##
## Write config to each matchbox host
## Hardcode each matchbox host until for_each module becomes available
##
module "ignition-kvm-0" {
  source = "../modulesv2/ignition"

  services          = local.services
  controller_params = module.kubernetes-common.controller_params
  worker_params     = module.kubernetes-common.worker_params
  gateway_params    = module.gateway-common.gateway_params
  renderer          = local.renderers.kvm-0
}

module "ignition-kvm-1" {
  source = "../modulesv2/ignition"

  services          = local.services
  controller_params = module.kubernetes-common.controller_params
  worker_params     = module.kubernetes-common.worker_params
  gateway_params    = module.gateway-common.gateway_params
  renderer          = local.renderers.kvm-1
}

# Test locally
module "ignition-local" {
  source = "../modulesv2/ignition"

  services          = local.services
  controller_params = module.kubernetes-common.controller_params
  worker_params     = module.kubernetes-common.worker_params
  gateway_params    = module.gateway-common.gateway_params
  renderer          = local.local_renderer
}

# Write admin kubeconfig file
resource "local_file" "kubeconfig-admin" {
  content = templatefile("${path.module}/../templates/manifest/kubeconfig_admin.yaml.tmpl", {
    cluster_name       = module.kubernetes-common.cluster_name
    ca_pem             = replace(base64encode(chomp(module.kubernetes-common.kubernetes_ca_pem)), "\n", "")
    cert_pem           = replace(base64encode(chomp(module.kubernetes-common.kubernetes_cert_pem)), "\n", "")
    private_key_pem    = replace(base64encode(chomp(module.kubernetes-common.kubernetes_private_key_pem)), "\n", "")
    apiserver_endpoint = module.kubernetes-common.apiserver_endpoint
  })
  filename = "output/${module.kubernetes-common.cluster_name}.kubeconfig"
}