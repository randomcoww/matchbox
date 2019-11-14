resource "kubernetes_cluster_role" "kube-apiserver-to-kubelet" {
  metadata {
    name = "system:kube-apiserver-to-kubelet"
  }
  rule {
    api_groups = [""]
    resources  = ["nodes/proxy", "nodes/stats", "nodes/log", "nodes/spec", "nodes/metrics"]
    verbs      = ["*"]
  }
}

resource "kubernetes_cluster_role_binding" "kube-apiserver" {
  metadata {
    name = "system:kube-apiserver"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:kube-apiserver-to-kubelet"
  }
  subject {
    kind      = "User"
    name      = "kubernetes"
    api_group = "rbac.authorization.k8s.io"
  }
}