resource "kubernetes_service_account" "kube-proxy" {
  metadata {
    name      = "kube-proxy"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "system-kube-proxy" {
  metadata {
    name = "system:kube-proxy"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "kube-proxy"
    namespace = "kube-system"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:node-proxier"
  }
}

resource "kubernetes_config_map" "kube-proxy-config" {
  metadata {
    name      = "kube-proxy-config"
    namespace = "kube-system"
  }
  data = {
    "kube-proxy-config.yaml" = <<EOF
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
featureGates:
  SupportIPVSProxyMode: true
mode: "ipvs"
clusterCIDR: "${var.networks.kubernetes.network}/${var.networks.kubernetes.cidr}"
iptables:
  masqueradeAll: true
EOF
  }
}

resource "kubernetes_daemonset" "kube-proxy" {
  metadata {
    name      = "kube-proxy"
    namespace = "kube-system"
    labels = {
      k8s-app = "kube-proxy"
    }
  }
  spec {
    selector {
      match_labels = {
        k8s-app = "kube-proxy"
      }
    }
    template {
      metadata {
        labels = {
          k8s-app = "kube-proxy"
        }
      }
      spec {
        volume {
          name = "xtables-lock"
          host_path {
            path = "/run/xtables.lock"
            type = "FileOrCreate"
          }
        }
        volume {
          name = "lib-modules"
          host_path {
            path = "/lib/modules"
          }
        }
        volume {
          name = "kube-proxy-config"
          config_map {
            name = "kube-proxy-config"
          }
        }
        container {
          name    = "kube-proxy"
          image   = var.container_images.kube_proxy
          command = ["kube-proxy", "--config=/etc/kube-proxy/kube-proxy-config.yaml"]
          env {
            name  = "KUBERNETES_SERVICE_HOST"
            value = var.services.kubernetes_apiserver.vip
          }
          env {
            name  = "KUBERNETES_SERVICE_PORT"
            value = var.services.kubernetes_apiserver.ports.secure
          }
          volume_mount {
            name       = "xtables-lock"
            mount_path = "/run/xtables.lock"
          }
          volume_mount {
            name       = "lib-modules"
            read_only  = true
            mount_path = "/lib/modules"
          }
          volume_mount {
            name       = "kube-proxy-config"
            mount_path = "/etc/kube-proxy/"
          }
          security_context {
            privileged = true
          }
        }
        service_account_name = "kube-proxy"
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
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = "10%"
      }
    }
  }
}