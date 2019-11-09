locals {
  ca_config = {
    matchbox-ca = {
      common_name = "matchbox"
      organization = "matchbox"
    }
    kubernetes-ca = {
      common_name = "kubernetes"
      organization = "kubernetes"
    }
    etcd-ca = {
      common_name = "etcd-ca"
      organization = "etcd"
    }
    service-account-ca = {
      common_name = "kubernetes"
      organization = "kubernetes"
    }
  }

  cert_config = {
    kubernetes-client = {
      ca = "kubernetes-ca"
      common_name  = "admin"
      organization = "system:masters"
    }
    matchbox = {
      ca = "matchbox-ca"
      common_name = "matchbox"
      ip_addresses = [
        "127.0.0.1"
      ]
    }
    matchbox-client = {
      ca = "matchbox-ca"
      common_name = "matchbox"
      ip_addresses = [
        "127.0.0.1"
      ]
    }
  }

  ca = {
    for k in keys(local.ca_config):
    k => {
      algorithm = tls_private_key.ca[k].algorithm
      private_key_pem = tls_private_key.ca[k].private_key_pem
      cert_pem = tls_self_signed_cert.ca[k].cert_pem
    }
  }
}

##
## CA
##
resource "tls_private_key" "ca" {
  for_each = local.ca_config

  algorithm   = "ECDSA"
  ecdsa_curve = "P521"
}

resource "tls_self_signed_cert" "ca" {
  for_each = local.ca_config

  key_algorithm   = tls_private_key.ca[each.key].algorithm
  private_key_pem = tls_private_key.ca[each.key].private_key_pem
  validity_period_hours = 8760
  is_ca_certificate     = true

  subject {
    common_name = lookup(each.value, "common_name", "")
    organization = lookup(each.value, "organization", "")
  }

  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]
}

##
## cert
##
resource "tls_private_key" "cert" {
  for_each = local.cert_config

  algorithm   = "ECDSA"
  ecdsa_curve = "P521"
}

resource "tls_cert_request" "cert" {
  for_each = local.cert_config

  key_algorithm   = tls_private_key.cert[each.key].algorithm
  private_key_pem = tls_private_key.cert[each.key].private_key_pem
  ip_addresses = lookup(each.value, "ip_addresses", [])

  subject {
    common_name = lookup(each.value, "common_name", "")
    organization = lookup(each.value, "organization", "")
  }
}

resource "tls_locally_signed_cert" "cert" {
  for_each = local.cert_config

  cert_request_pem   = tls_cert_request.cert[each.key].cert_request_pem
  ca_key_algorithm   = tls_private_key.ca[each.value.ca].algorithm
  ca_private_key_pem = tls_private_key.ca[each.value.ca].private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca[each.value.ca].cert_pem
  
  validity_period_hours = 8760
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth",
  ]
}

##
## SSH CA for all hosts
##
resource "tls_private_key" "ssh-ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P521"
}

## ssh ca
resource "local_file" "ssh-ca-key" {
  content  = chomp(tls_private_key.ssh-ca.private_key_pem)
  filename = "output/ssh-ca-key.pem"
}