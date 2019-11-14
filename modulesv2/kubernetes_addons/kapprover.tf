resource "kubernetes_service_account" "kubelet-approver" {
  metadata {
    name      = "kubelet-approver"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role" "kubelet-approver" {
  metadata {
    name = "kubelet-approver"
  }
  rule {
    verbs      = ["get", "list", "delete", "watch"]
    api_groups = ["certificates.k8s.io"]
    resources  = ["certificatesigningrequests"]
  }
  rule {
    verbs      = ["update"]
    api_groups = ["certificates.k8s.io"]
    resources  = ["certificatesigningrequests/approval"]
  }
}

resource "kubernetes_cluster_role_binding" "kubelet-approver" {
  metadata {
    name = "kubelet-approver"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "kubelet-approver"
    namespace = "kube-system"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "kubelet-approver"
  }
}

resource "kubernetes_deployment" "kubelet-approver" {
  metadata {
    name      = "kubelet-approver"
    namespace = "kube-system"
    labels = {
      k8s-app = "kubelet-approver"
    }
  }
  spec {
    replicas = 1
    template {
      metadata {
        name = "kubelet-approver"
        labels = {
          k8s-app = "kubelet-approver"
        }
      }
      spec {
        container {
          name  = "kubelet-approver"
          image = var.container_images.kapprover
          resources {
            limits {
              cpu    = "100m"
              memory = "50Mi"
            }
            requests {
              cpu    = "100m"
              memory = "50Mi"
            }
          }
          image_pull_policy = "IfNotPresent"
        }
        service_account_name = "kubelet-approver"
      }
    }
  }
}