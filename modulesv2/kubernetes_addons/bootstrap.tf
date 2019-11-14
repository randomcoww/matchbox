resource "kubernetes_cluster_role_binding" "kubelet-bootstrap" {
  metadata {
    name = "kubelet-bootstrap"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:node-bootstrapper"
  }
  subject {
    kind      = "User"
    name      = "kubelet-bootstrap"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_cluster_role_binding" "node-client-auto-approve-csr" {
  metadata {
    name = "node-client-auto-approve-csr"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:certificates.k8s.io:certificatesigningrequests:nodeclient"
  }
  subject {
    kind      = "Group"
    name      = "system:node-bootstrapper"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_cluster_role_binding" "node-client-auto-renew-crt" {
  metadata {
    name = "node-client-auto-renew-crt"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:certificates.k8s.io:certificatesigningrequests:selfnodeclient"
  }
  subject {
    kind      = "Group"
    name      = "system:nodes"
    api_group = "rbac.authorization.k8s.io"
  }
}
