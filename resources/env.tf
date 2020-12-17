locals {
  # Default user for CoreOS and Silverblue
  user        = "core"
  client_user = "randomcoww"
  # Desktop env user. This affects the persistent home directory.
  # S3 backup for etcd
  # path is based on the cluster name
  aws_region              = "us-west-2"
  s3_etcd_backup_bucket   = "randomcoww-etcd-backup"
  kubernetes_cluster_name = "default-cluster-2012-1"
  # kubelet image is used for static pods and does not need to match the kubernetes version
  # hyperkube is used for the worker kubelet and should match the version
  container_images = {
    kubelet                 = "docker.io/randomcoww/kubernetes:kubelet-v1.20.0"
    kube_apiserver          = "docker.io/randomcoww/kubernetes:kube-master-v1.20.0"
    kube_controller_manager = "docker.io/randomcoww/kubernetes:kube-master-v1.20.0"
    kube_scheduler          = "docker.io/randomcoww/kubernetes:kube-master-v1.20.0"
    hyperkube               = "docker.io/randomcoww/kubernetes:kubelet-v1.20.0"
    kube_proxy              = "docker.io/randomcoww/kubernetes:kube-proxy-v1.20.0"
    etcd_wrapper            = "docker.io/randomcoww/etcd-wrapper:v0.2.1"
    etcd                    = "docker.io/randomcoww/etcd:v3.4.13"
    flannel                 = "docker.io/randomcoww/flannel:latest"
    keepalived              = "docker.io/randomcoww/keepalived:latest"
    cni_plugins             = "docker.io/randomcoww/cni-plugins:v0.8.7"
    coredns                 = "docker.io/coredns/coredns:1.8.0"
    external_dns            = "registry.opensource.zalan.do/teapot/external-dns:latest"
    kapprover               = "docker.io/randomcoww/kapprover:v0.0.4"
    kea                     = "docker.io/randomcoww/kea:1.8.1"
    conntrackd              = "docker.io/randomcoww/conntrackd:latest"
    promtail                = "docker.io/randomcoww/promtail:v2.0.0"
    matchbox                = "quay.io/poseidon/matchbox:latest"
  }

  services = {
    # hypervisor internal
    renderer = {
      vlan = "metadata"
      vip  = "192.168.224.1"
      ports = {
        http = 80
        rpc  = 58081
      }
    }

    # gateway
    kea = {
      ports = {
        peer = 58082
      }
    }
    recursive_dns = {
      vlan = "nat"
      vip  = "192.168.94.241"
      ports = {
        prometheus = 59153
      }
    }
    # Resolve ingress and metallb names - should be in a metallb pool
    internal_dns = {
      vlan = "nat"
      vip  = "192.168.126.127"
      ports = {
        prometheus = 59153
      }
    }
    upstream_dns = {
      vip = "9.9.9.9"
      url = "dns.quad9.net"
    }

    # Log collector - should be in metallb a pool
    loki = {
      vlan = "nat"
      vip  = "192.168.126.126"
      ports = {
        http_listen = 3100
      }
    }

    # kubernetes network
    kubernetes_apiserver = {
      vlan = "internal"
      vip  = "192.168.126.245"
      ports = {
        secure = 56443
      }
    }
    kubernetes_service = {
      vlan = "kubernetes_service"
      vip  = "10.96.0.1"
    }
    kubernetes_dns = {
      vlan = "kubernetes_service"
      vip  = "10.96.0.10"
    }
    etcd = {
      ports = {
        peer   = 52380
        client = 52379
      }
    }

    # Externally forwarded to internal IP - should be in a metallb pool
    external_dnat = {
      vlan = "nat"
      vip  = "192.168.94.125"
      ports = {
        https = 8080
      }
    }

    # nodePort and clusterIP must be specified for LB services to work with
    # the terraform kubernetes-alpha provider. Probably a bug?
    # TODO: Remove once not needed by provider
    kubernetes_external_dns_tcp = {
      vip = "10.100.0.100"
      ports = {
        node = 31800
      }
    }
    kubernetes_external_dns_udp = {
      vip = "10.100.0.101"
      ports = {
        node = 31801
      }
    }
    kubernetes_loki = {
      vip = "10.100.0.102"
      ports = {
        node = 31802
      }
    }
  }

  domains = {
    internal           = "fuzzybunny.internal"
    internal_mdns      = "local"
    kubernetes_cluster = "cluster.internal"
  }

  components = {
    base = {
      nodes = [
        "gateway-0",
        "gateway-1",
        "ns-0",
        "ns-1",
        "controller-0",
        "controller-1",
        "controller-2",
        "worker-0",
        "worker-1",
        "worker-2",
        "kvm-0",
        "kvm-1",
        "kvm-2",
        "test-0",
        "client-0",
        "client-1",
      ]
    }
    # coreos hypervisor
    hypervisor = {
      nodes = [
        "kvm-0",
        "kvm-1",
        "kvm-2",
      ]
      pxe_image_mount_path = "/run/media/iso/images/pxeboot"
      kernel_image         = "vmlinuz"
      initrd_images = [
        "initrd.img",
        "rootfs.img",
      ]
      metadata = {
        vlan = "metadata"
        if   = "en-md"
        ip   = local.services.renderer.vip
      }
    }
    # coreos VMs
    vm = {
      nodes = [
        "gateway-0",
        "gateway-1",
        "ns-0",
        "ns-1",
        "controller-0",
        "controller-1",
        "controller-2",
        "worker-0",
        "worker-1",
        "worker-2",
        "test-0",
      ]
      kernel_params = [
        "console=hvc0",
        "rd.neednet=1",
        "ignition.firstboot",
        "ignition.platform.id=metal",
        "systemd.unified_cgroup_hierarchy=0",
      ]
      metadata = {
        vlan = "metadata"
        if   = "ens2"
      }
    }
    server = {
      nodes = [
        "gateway-0",
        "gateway-1",
        "ns-0",
        "ns-1",
        "controller-0",
        "controller-1",
        "controller-2",
        "worker-0",
        "worker-1",
        "worker-2",
        "kvm-0",
        "kvm-1",
        "kvm-2",
        "test-0",
      ]
    }
    # silverblue (gnome) desktop with networkmanager
    client = {
      nodes = [
        "client-0",
        "client-1",
      ]
      disk = [
        {
          device     = "/dev/disk/by-label/localhome"
          mount_path = "/var/home/${local.client_user}"
        },
      ]
      client_user     = local.client_user
      client_user_uid = 10000
    }
    laptop = {
      nodes = [
        "client-1",
      ]
    }
    # server certs for SSH CA
    ssh_server = {
      nodes = [
        "gateway-0",
        "gateway-1",
        "ns-0",
        "ns-1",
        "controller-0",
        "controller-1",
        "controller-2",
        "worker-0",
        "worker-1",
        "worker-2",
        "kvm-0",
        "kvm-1",
        "kvm-2",
        "test-0",
      ]
    }
    ssh_client = {
      nodes = [
        "client-0",
        "client-1",
      ]
    }
    # cert for fuzzybunny.internal
    ingress = {
      nodes = [
        "client-0",
        "client-1",
      ]
    }
    # promtail to push logs to loki (non kubernetes containerd hosts)
    static_pod_logging = {
      nodes = [
        "ns-0",
        "ns-1",
        "controller-0",
        "controller-1",
        "controller-2",
      ]
    }

    # host specific
    gateway = {
      memory = 4
      vcpu   = 1
      nodes = [
        "gateway-0",
        "gateway-1",
      ]
    }
    ns = {
      memory = 4
      vcpu   = 1
      nodes = [
        "ns-0",
        "ns-1",
      ]
    }
    controller = {
      memory = 6
      vcpu   = 2
      nodes = [
        "controller-0",
        "controller-1",
        "controller-2",
      ]
    }
    worker = {
      memory = 36
      vcpu   = 4
      network = [
        {
          vlan = "internal"
          if   = "ens3"
          dhcp = true
        },
        {
          vlan = "nat"
          if   = "ens4"
          dhcp = true
        },
      ]
      nodes = [
        "worker-0",
        "worker-1",
        "worker-2",
      ]
      hostdev = [
        "chipset-sata",
        "hba",
      ]
    }
    test = {
      memory = 3
      vcpu   = 1
      nodes = [
        "test-0",
      ]
    }
  }

  networks = {
    # services - no route to wan
    internal = {
      id        = 1
      network   = "192.168.126.0"
      cidr      = 23
      dhcp_pool = "192.168.127.64/26"
      mdns      = true
      mtu       = 9000
    }
    # services
    nat = {
      id        = 120
      network   = "192.168.94.0"
      cidr      = 23
      router    = "192.168.94.240"
      dhcp_pool = "192.168.95.64/26"
      mtu       = 9000
    }
    # main
    lan = {
      id        = 90
      network   = "192.168.62.0"
      cidr      = 23
      router    = "192.168.62.240"
      dhcp_pool = "192.168.63.64/26"
      mtu       = 9000
    }
    # gateway conntrack sync and backup route
    sync = {
      id      = 60
      network = "192.168.190.0"
      cidr    = 29
      router  = "192.168.190.6"
      mtu     = 9000
    }
    wan = {
      id = 30
    }
    # internal network on each hypervisor for PXE bootstrap
    metadata = {
      network   = "192.168.224.0"
      cidr      = 23
      dhcp_pool = "192.168.225.64/26"
    }
    # kubernetes internal
    kubernetes = {
      network = "10.244.0.0"
      cidr    = 16
    }
    kubernetes_service = {
      network = "10.96.0.0"
      cidr    = 12
    }
  }

  loadbalancer_pools = {
    kubernetes-nat = {
      network = "192.168.94.64"
      cidr    = 26
    }
    kubernetes-internal = {
      network = "192.168.126.64"
      cidr    = 26
    }
  }

  hosts = {
    # Interface name should always start at ens2 and count up
    # libvirt auto assigns interfaces starting at 00:02.0 and
    # increments the slot for each element.
    # Metadata network uses ens2. Start host specific
    # interfaces at ens3.

    # Gateway
    gateway-0 = {
      # Duplicate MAC VRRP (e.g. keepalived) do not work for IP traffic from other VFs on the same NIC.
      # If a MAC exists on another VF on the same hardware, it seems to bypass the switch and get priority
      # over other MACs on the same network even if the VF has no IP.
      network = [
        {
          vlan = "internal"
          ip   = "192.168.127.217"
          if   = "ens3"
        },
        {
          vlan = "nat"
          if   = "ens4"
          # Duplicate this on gateways
          mac = "00-00-5e-00-01-01"
        },
        {
          vlan = "lan"
          if   = "ens5"
          # Duplicate this on gateways
          mac = "00-00-5e-00-01-02"
        },
        {
          vlan = "sync"
          ip   = "192.168.190.1"
          if   = "ens6"
        },
        {
          vlan = "wan"
          if   = "ens7"
          dhcp = true
          # Duplicate this on gateways
          mac = "52-54-00-63-6e-b3"
        },
      ]
    }
    gateway-1 = {
      network = [
        {
          vlan = "internal"
          ip   = "192.168.127.218"
          if   = "ens3"
        },
        {
          vlan = "nat"
          if   = "ens4"
          # Duplicate this on gateways
          mac = "00-00-5e-00-01-01"
        },
        {
          vlan = "lan"
          if   = "ens5"
          # Duplicate this on gateways
          mac = "00-00-5e-00-01-02"
        },
        {
          vlan = "sync"
          ip   = "192.168.190.2"
          if   = "ens6"
        },
        {
          vlan = "wan"
          if   = "ens7"
          dhcp = true
          # Duplicate this on gateways
          mac = "52-54-00-63-6e-b3"
        },
      ]
    }

    # Nameserver with DHCP
    ns-0 = {
      network = [
        {
          vlan = "internal"
          ip   = "192.168.127.222"
          if   = "ens3"
        },
        {
          vlan = "nat"
          ip   = "192.168.95.222"
          if   = "ens4"
        },
        {
          vlan = "lan"
          ip   = "192.168.63.222"
          if   = "ens5"
        },
      ]
      kea_ha_role = "primary"
    }
    ns-1 = {
      network = [
        {
          vlan = "internal"
          ip   = "192.168.127.223"
          if   = "ens3"
        },
        {
          vlan = "nat"
          ip   = "192.168.95.223"
          if   = "ens4"
        },
        {
          vlan = "lan"
          ip   = "192.168.63.223"
          if   = "ens5"
        },
      ]
      kea_ha_role = "secondary"
    }

    # Controllers
    controller-0 = {
      network = [
        {
          vlan = "internal"
          ip   = "192.168.127.219"
          if   = "ens3"
        },
        {
          vlan = "nat"
          if   = "ens4"
          dhcp = true
        },
      ]
    }
    controller-1 = {
      network = [
        {
          vlan = "internal"
          ip   = "192.168.127.220"
          if   = "ens3"
        },
        {
          vlan = "nat"
          if   = "ens4"
          dhcp = true
        },
      ]
    }
    controller-2 = {
      network = [
        {
          vlan = "internal"
          ip   = "192.168.127.221"
          if   = "ens3"
        },
        {
          vlan = "nat"
          if   = "ens4"
          dhcp = true
        },
      ]
    }

    # Workers
    # Network config is same for all hosts
    worker-0 = {
      # Defaults:
      # format = "xfs"
      # wipe_filesystem = false
      disk = [
        {
          label      = "2YK7XTRD"
          device     = "/dev/disk/by-id/ata-WDC_WD100EFAX-68LHPN0_2YK7XTRD"
          mount_path = "/var/s3/0"
        },
        {
          label      = "2YK87AVD"
          device     = "/dev/disk/by-id/ata-WDC_WD100EFAX-68LHPN0_2YK87AVD"
          mount_path = "/var/s3/1"
        },
        {
          label      = "2YK89PND"
          device     = "/dev/disk/by-id/ata-WDC_WD100EFAX-68LHPN0_2YK89PND"
          mount_path = "/var/s3/2"
        },
        {
          label      = "2YKG1X2D"
          device     = "/dev/disk/by-id/ata-WDC_WD100EFAX-68LHPN0_2YKG1X2D"
          mount_path = "/var/s3/3"
        },
        {
          label      = "2YKGML5D"
          device     = "/dev/disk/by-id/ata-WDC_WD100EFAX-68LHPN0_2YKGML5D"
          mount_path = "/var/s3/4"
        },
        {
          label      = "2YKGML7D"
          device     = "/dev/disk/by-id/ata-WDC_WD100EFAX-68LHPN0_2YKGML7D"
          mount_path = "/var/s3/5"
        },
        {
          label      = "2YKGNL4D"
          device     = "/dev/disk/by-id/ata-WDC_WD100EFAX-68LHPN0_2YKGNL4D"
          mount_path = "/var/s3/6"
        },
        {
          label      = "JEK830AZ"
          device     = "/dev/disk/by-id/ata-WDC_WD100EFAX-68LHPN0_JEK830AZ"
          mount_path = "/var/s3/7"
        },
        {
          label      = "JEK830RZ"
          device     = "/dev/disk/by-id/ata-WDC_WD100EFAX-68LHPN0_JEK830RZ"
          mount_path = "/var/s3/8"
        },
        {
          label      = "JEK8V1YZ"
          device     = "/dev/disk/by-id/ata-WDC_WD100EFAX-68LHPN0_JEK8V1YZ"
          mount_path = "/var/s3/9"
        },
        {
          label      = "JEK8YTSZ"
          device     = "/dev/disk/by-id/ata-WDC_WD100EFAX-68LHPN0_JEK8YTSZ"
          mount_path = "/var/s3/10"
        },
        {
          label      = "JEKAZ92N"
          device     = "/dev/disk/by-id/ata-WDC_WD100EFAX-68LHPN0_JEKAZ92N"
          mount_path = "/var/s3/11"
        },
        {
          device     = "/dev/disk/by-id/ata-Samsung_SSD_860_QVO_1TB_S4PGNF0M414895K"
          mount_path = "/var/lib/kubelet/pv"
        },
      ]
      node_labels = {
        "minio-data"        = "true"
        "openebs.io/engine" = "mayastor"
      }
    }
    worker-1 = {
      disk = [
        {
          device     = "/dev/disk/by-id/ata-Samsung_SSD_860_QVO_1TB_S4PGNF0M410395Z"
          mount_path = "/var/lib/kubelet/pv"
        },
      ]
      node_labels = {
        "openebs.io/engine" = "mayastor"
      }
    }
    worker-2 = {
    }

    # Test instances
    test-0 = {
      network = [
        {
          vlan = "internal"
          if   = "ens3"
          dhcp = true
        },
        {
          vlan = "nat"
          if   = "ens4"
          dhcp = true
        },
      ]
    }

    # KVM
    kvm-0 = {
      hwif = [
        {
          label = "pf0"
          if    = "en-pf0"
          mac   = "f4-52-14-7b-53-80"
        },
        {
          label = "pf1"
          if    = "en-pf1"
          mac   = "a0-36-9f-87-27-34"
        },
      ]
      network = [
        {
          vlan = "internal"
          if   = "en-int"
          ip   = "192.168.127.251"
          hwif = "pf0"
        },
        {
          vlan = "nat"
          if   = "en-nat"
          dhcp = true
          hwif = "pf0"
        },
      ]
      ## hypervisorf boot image is copied with coreos-installer to strip
      ## out ignition and re-used to boot VMs
      libvirt_domains = [
        {
          node = "gateway-0",
          # This cannot run on the same SRIOV pf as other VMs
          hwif = "pf1",
        },
        {
          node = "ns-0",
          hwif = "pf0",
        },
        {
          node = "controller-0",
          hwif = "pf0",
        },
        {
          node = "worker-0",
          hwif = "pf0",
        },
      ]
      dev = {
        # Chipset SATA
        chipset-sata = {
          domain   = "0x0000"
          bus      = "0x00"
          slot     = "0x17"
          function = "0x0"
        }
        # HBA addon card
        hba = {
          domain   = "0x0000"
          bus      = "0x02"
          slot     = "0x00"
          function = "0x0"
          rom      = "/etc/libvirt/boot/SAS9300_8i_IT.bin"
        }
      }
    }
    kvm-1 = {
      hwif = [
        {
          label = "pf0"
          if    = "en-pf0"
          mac   = "f4-52-14-80-6a-e0"
        },
        {
          label = "pf1"
          if    = "en-pf1"
          mac   = "a0-36-9f-87-2f-a0"
        },
      ]
      network = [
        {
          vlan = "internal"
          if   = "en-int"
          ip   = "192.168.127.252"
          hwif = "pf0"
        },
        {
          vlan = "nat"
          if   = "en-nat"
          dhcp = true
          hwif = "pf0"
        },
      ]
      ## hypervisor boot image is copied with coreos-installer to strip
      ## out ignition and re-used to boot VMs
      libvirt_domains = [
        {
          node = "gateway-1",
          # This cannot run on the same SRIOV pf as other VMs
          hwif = "pf1",
        },
        {
          node = "ns-1",
          hwif = "pf0",
        },
        {
          node = "controller-1",
          hwif = "pf0",
        },
        {
          node = "controller-2",
          hwif = "pf0",
        },
        {
          node = "worker-1",
          hwif = "pf0",
        },
      ]
      dev = {
        # Chipset SATA
        chipset-sata = {
          domain   = "0x0000"
          bus      = "0x00"
          slot     = "0x17"
          function = "0x0"
        }
        # HBA addon card
        hba = {
          domain   = "0x0000"
          bus      = "0x02"
          slot     = "0x00"
          function = "0x0"
          rom      = "/etc/libvirt/boot/SAS9300_8i_IT.bin"
        }
      }
    }
    kvm-2 = {
      hwif = [
        {
          label = "pf0"
          if    = "en-pf0"
          mac   = "3c-ec-ef-45-96-e6"
        },
        {
          label = "pf1"
          if    = "en-pf1"
          mac   = "3c-ec-ef-45-96-e7"
        },
        {
          label = "pf2"
          if    = "en-pf2"
          mac   = "3c-ec-ef-45-96-e8"
        },
        {
          label = "pf3"
          if    = "en-pf3"
          mac   = "3c-ec-ef-45-96-e9"
        },
      ]
      network = [
        {
          vlan = "internal"
          if   = "en-int"
          ip   = "192.168.127.250"
          hwif = "pf0"
        },
        {
          vlan = "nat"
          if   = "en-nat"
          dhcp = true
          hwif = "pf0"
        },
      ]
      ## hypervisor boot image is copied with coreos-installer to strip
      ## out ignition and re-used to boot VMs
      libvirt_domains = [
        {
          node = "gateway-1",
          # This cannot run on the same SRIOV pf as other VMs
          hwif = "pf1",
        },
        {
          node = "ns-1",
          hwif = "pf0",
        },
        {
          node = "controller-2",
          hwif = "pf1",
        },
        {
          node = "worker-2",
          hwif = "pf2",
        },
      ]
    }

    # client devices
    client-0 = {
      hwif = [
        {
          label = "pf0"
          if    = "enp4s0f0"
          # interface name instead of mac is needed for network manager
          # mac    = "f8-f2-1e-1e-3c-40"
        },
      ]
      network = [
        {
          vlan = "internal"
          if   = "en-int"
          ip   = "192.168.127.253"
          hwif = "pf0"
        },
        {
          vlan = "lan"
          if   = "en-lan"
          dhcp = true
          hwif = "pf0"
          mdns = true
        },
        {
          vlan     = "wan"
          if       = "en-wan"
          dhcp     = true
          hwif     = "pf0"
          disabled = true
        }
      ]
    }
    client-1 = {
    }

    # unmanaged hardware
    switch-0 = {
      network = [
        {
          vlan = "internal"
          ip   = "192.168.127.60"
          mac  = "50-c7-bf-60-78-22"
        },
      ]
    }
    ipmi-0 = {
      network = [
        {
          vlan = "internal"
          ip   = "192.168.127.62"
          mac  = "ac-1f-6b-86-06-82"
        },
      ]
    }
    ipmi-1 = {
      network = [
        {
          vlan = "internal"
          ip   = "192.168.127.61"
          mac  = "ac-1f-6b-ae-76-60"
        },
      ]
    }
    ipmi-2 = {
      network = [
        {
          vlan = "internal"
          ip   = "192.168.127.63"
          mac = "3c-ec-ef-45-97-77"
        }
      ]
    }
  }

  # similar to guests filter
  # control which configs are rendered on local matchbox
  local_renderer_hosts_include = [
    "kvm-0",
    "kvm-1",
    "kvm-2",
    "client-0",
    "client-1",
  ]
}