output "cluster_name" {
  value = var.cluster_name
}

output "apiserver_endpoint" {
  value = "https://${var.services.kubernetes_apiserver.vip}:${var.services.kubernetes_apiserver.ports.secure}"
}