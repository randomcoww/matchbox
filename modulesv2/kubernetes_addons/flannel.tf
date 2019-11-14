resource "kubernetes_cluster_role" "flannel" {
  metadata {
    name = "flannel"
  }
  rule {
    verbs      = ["get"]
    api_groups = [""]
    resources  = ["pods"]
  }
  rule {
    verbs      = ["list", "watch"]
    api_groups = [""]
    resources  = ["nodes"]
  }
  rule {
    verbs      = ["patch"]
    api_groups = [""]
    resources  = ["nodes/status"]
  }
}

resource "kubernetes_cluster_role_binding" "flannel" {
  metadata {
    name = "flannel"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "flannel"
    namespace = "kube-system"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "flannel"
  }
}

resource "kubernetes_service_account" "flannel" {
  metadata {
    name      = "flannel"
    namespace = "kube-system"
  }
}

resource "kubernetes_config_map" "kube-flannel-cfg" {
  metadata {
    name      = "kube-flannel-cfg"
    namespace = "kube-system"
    labels = {
      app = "flannel"
      tier = "node"
    }
  }
  data = {
    "cni-conf.json" = jsonencode({
      name = "cbr0"
      plugins = [
        {
          type = "flannel"
          delegate = {
            hairpinMode = true
            isDefaultGateway = true
          }
        },
        {
          type = "portmap"
          capabilities = {
            portMappings = true
          }
        }
      ]
    })
    "net-conf.json" = jsonencode({
      Network = "${var.networks.kubernetes.network}/${var.networks.kubernetes.cidr}"
      Backend = {
        Type = "host-gw"
      }
    })
  }
}

resource "kubernetes_daemonset" "kube-flannel" {
  metadata {
    name      = "kube-flannel-ds-amd64"
    namespace = "kube-system"
    labels = {
      app = "flannel"
      tier = "node"
    }
  }
  spec {
    template {
      metadata {
        labels = {
          app = "flannel"
          tier = "node"
        }
      }
      spec {
        volume {
          name = "cni-plugins"
          host_path {
            path = "/opt/cni/bin"
          }
        }
        volume {
          name = "run"
          host_path {
            path = "/run"
          }
        }
        volume {
          name = "cni"
          host_path {
            path = "/etc/cni/net.d"
          }
        }
        volume {
          name = "flannel-cfg"
          config_map {
            name = "kube-flannel-cfg"
          }
        }
        init_container {
          name  = "install-cni-plugins"
          image = var.container_images.cni_plugins
          volume_mount {
            name       = "cni-plugins"
            mount_path = "/opt/cni/bin"
          }
        }
        init_container {
          name    = "install-cni"
          image   = var.container_images.flannel
          command = ["cp"]
          args    = ["-f", "/etc/kube-flannel/cni-conf.json", "/etc/cni/net.d/10-flannel.conflist"]
          volume_mount {
            name       = "cni"
            mount_path = "/etc/cni/net.d"
          }
          volume_mount {
            name       = "flannel-cfg"
            mount_path = "/etc/kube-flannel/"
          }
        }
        container {
          name    = "kube-flannel"
          image   = var.container_images.flannel
          command = ["/opt/bin/flanneld"]
          args    = ["--ip-masq", "--kube-subnet-mgr"]
          env {
            name = "POD_NAME"
            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }
          env {
            name = "POD_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }
          volume_mount {
            name       = "run"
            mount_path = "/run"
          }
          volume_mount {
            name       = "flannel-cfg"
            mount_path = "/etc/kube-flannel/"
          }
          security_context {
            privileged = true
          }
        }
        node_selector = {
          "beta.kubernetes.io/arch" = "amd64"
        }
        service_account_name = "flannel"
        host_network         = true
        toleration {
          operator = "Exists"
          effect   = "NoExecute"
        }
        toleration {
          operator = "Exists"
          effect   = "NoSchedule"
        }
      }
    }
  }
}