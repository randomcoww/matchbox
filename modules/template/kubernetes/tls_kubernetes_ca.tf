resource "tls_private_key" "kubernetes-ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P521"
}

resource "tls_self_signed_cert" "kubernetes-ca" {
  key_algorithm   = tls_private_key.kubernetes-ca.algorithm
  private_key_pem = tls_private_key.kubernetes-ca.private_key_pem

  validity_period_hours = 8760
  is_ca_certificate     = true

  subject {
    common_name  = "kubernetes"
    organization = "kubernetes"
  }

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature",
  ]
}
