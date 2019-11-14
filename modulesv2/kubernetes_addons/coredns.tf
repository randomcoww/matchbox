resource "kubernetes_service_account" "coredns" {
  metadata {
    name      = "coredns"
    namespace = "kube-system"
    labels = {
      "addonmanager.kubernetes.io/mode" = "Reconcile"
      "kubernetes.io/cluster-service" = "true"
    }
  }
}

resource "kubernetes_cluster_role" "system-coredns" {
  metadata {
    name = "system:coredns"
    labels = {
      "addonmanager.kubernetes.io/mode" = "Reconcile"
      "kubernetes.io/bootstrapping" = "rbac-defaults"
    }
  }
  rule {
    verbs      = ["list", "watch"]
    api_groups = [""]
    resources  = ["endpoints", "namespaces"]
  }
  rule {
    verbs      = ["get", "list", "watch"]
    api_groups = [""]
    resources  = ["services", "pods"]
  }
  rule {
    verbs      = ["get", "list"]
    api_groups = [""]
    resources  = ["nodes"]
  }
  rule {
    verbs      = ["get", "watch", "list"]
    api_groups = ["extensions"]
    resources  = ["ingresses"]
  }
}

resource "kubernetes_cluster_role_binding" "system-coredns" {
  metadata {
    name = "system:coredns"
    labels = {
      "addonmanager.kubernetes.io/mode" = "EnsureExists"
      "kubernetes.io/bootstrapping" = "rbac-defaults"
    }
    annotations = {
      "rbac.authorization.kubernetes.io/autoupdate" = "true"
    }
  }
  subject {
    kind      = "ServiceAccount"
    name      = "coredns"
    namespace = "kube-system"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:coredns"
  }
}

resource "kubernetes_config_map" "coredns" {
  metadata {
    name      = "coredns"
    namespace = "kube-system"
    labels = {
      "addonmanager.kubernetes.io/mode" = "EnsureExists"
    }
  }
  data = {
    Corefile = <<EOF
.:53 {
  errors
  health
  ${var.domains.kubernetes_cluster} in-addr.arpa ip6.arp {
    pods insecure
    upstream
    fallthrough in-addr.arpa ip6.arpa
  }
  etcd ${var.domains.internal} in-addr.arpa ip6.arp {
    fallthrough in-addr.arpa ip6.arpa
  }
  forward . ${var.services.recursive_dns.vip}
  prometheus :9153
  cache 30
  reload
  loadbalance
}
EOF
  }
}

resource "kubernetes_deployment" "coredns" {
  metadata {
    name      = "coredns"
    namespace = "kube-system"
    labels = {
      "addonmanager.kubernetes.io/mode" = "Reconcile"
      k8s-app = "kube-dns"
      "kubernetes.io/cluster-service" = "true"
      "kubernetes.io/name" = "CoreDNS"
    }
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        k8s-app = "kube-dns"
      }
    }
    template {
      metadata {
        labels = {
          k8s-app = "kube-dns"
        }
      }
      spec {
        volume {
          name = "config-volume"
          config_map {
            name = "coredns"
            items {
              key  = "Corefile"
              path = "Corefile"
            }
          }
        }
        container {
          name  = "coredns"
          image = var.container_images.coredns
          args  = ["-conf", "/etc/coredns/Corefile"]
          port {
            name           = "dns"
            container_port = 53
            protocol       = "UDP"
          }
          port {
            name           = "dns-tcp"
            container_port = 53
            protocol       = "TCP"
          }
          port {
            name           = "metrics"
            container_port = 9153
            protocol       = "TCP"
          }
          resources {
            limits {
              memory = "170Mi"
            }
            requests {
              cpu    = "100m"
              memory = "70Mi"
            }
          }
          volume_mount {
            name       = "config-volume"
            read_only  = true
            mount_path = "/etc/coredns"
          }
          liveness_probe {
            http_get {
              path   = "/health"
              port   = "8080"
              scheme = "HTTP"
            }
            initial_delay_seconds = 60
            timeout_seconds       = 5
            success_threshold     = 1
            failure_threshold     = 5
          }
          readiness_probe {
            http_get {
              path   = "/health"
              port   = "8080"
              scheme = "HTTP"
            }
          }
          image_pull_policy = "IfNotPresent"
          security_context {
            read_only_root_filesystem = true
          }
        }
        container {
          name    = "etcd"
          image   = var.container_images.etcd
          command = ["/usr/local/bin/etcd"]
        }
        container {
          name  = "external-dns"
          image = "registry.opensource.zalan.do/teapot/external-dns:latest"
          args  = ["--source=service", "--source=ingress", "--provider=coredns", "--log-level=debug"]
        }
        dns_policy = "Default"
        node_selector = {
          "beta.kubernetes.io/os" = "linux"
        }
        service_account_name = "coredns"
        toleration {
          key      = "CriticalAddonsOnly"
          operator = "Exists"
        }
      }
    }
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = "1"
      }
    }
  }
}

resource "kubernetes_service" "external-dns-tcp" {
  metadata {
    name      = "external-dns-tcp"
    namespace = "kube-system"
    annotations = {
      "metallb.universe.tf/allow-shared-ip" = "external-dns"
    }
  }
  spec {
    port {
      name        = "default"
      port        = 53
      target_port = "53"
    }
    selector = {
      k8s-app = "kube-dns"
    }
    type             = "LoadBalancer"
    load_balancer_ip = var.services.internal_dns.vip
  }
}

resource "kubernetes_service" "external-dns-udp" {
  metadata {
    name      = "external-dns-udp"
    namespace = "kube-system"
    annotations = {
      "metallb.universe.tf/allow-shared-ip" = "external-dns"
    }
  }
  spec {
    port {
      name        = "default"
      protocol    = "UDP"
      port        = 53
      target_port = "53"
    }
    selector = {
      k8s-app = "kube-dns"
    }
    type             = "LoadBalancer"
    load_balancer_ip = var.services.internal_dns.vip
  }
}

resource "kubernetes_service" "kube-dns" {
  metadata {
    name      = "kube-dns"
    namespace = "kube-system"
    labels = {
      k8s-app = "kube-dns"
      "kubernetes.io/cluster-service" = "true"
      "kubernetes.io/name" = "CoreDNS"
    }
    annotations = {
      "prometheus.io/port" = "9153"
      "prometheus.io/scrape" = "true"
    }
  }
  spec {
    port {
      name     = "dns"
      protocol = "UDP"
      port     = 53
    }
    port {
      name     = "dns-tcp"
      protocol = "TCP"
      port     = 53
    }
    port {
      name     = "dns-tls"
      protocol = "TCP"
      port     = 9153
    }
    selector = {
      k8s-app = "kube-dns"
    }
    cluster_ip = var.services.kubernetes_dns.vip
  }
}

