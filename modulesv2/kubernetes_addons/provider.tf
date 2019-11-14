provider "kubernetes" {
  host = var.apiserver_endpoint
  client_certificate     = var.cert_pem
  client_key             = var.private_key_pem
  cluster_ca_certificate = var.ca_pem
}
