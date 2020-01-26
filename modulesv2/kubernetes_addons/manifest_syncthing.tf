# resource "tls_private_key" "syncthing-ca" {
#   algorithm   = "ECDSA"
#   ecdsa_curve = "P521"
# }

# resource "tls_self_signed_cert" "syncthing-ca" {
#   key_algorithm   = tls_private_key.syncthing-ca.algorithm
#   private_key_pem = tls_private_key.syncthing-ca.private_key_pem

#   validity_period_hours = 8760
#   is_ca_certificate     = true

#   subject {
#     common_name  = "syncthing"
#     organization = "syncthing"
#   }

#   allowed_uses = [
#     "cert_signing",
#     "crl_signing",
#     "digital_signature",
#   ]
# }

# resource "tls_private_key" "syncthing" {
#   for_each = var.syncthing_pods

#   algorithm   = "ECDSA"
#   ecdsa_curve = "P384"
# }

# resource "tls_cert_request" "syncthing" {
#   for_each = var.syncthing_pods

#   key_algorithm   = tls_private_key.syncthing[each.key].algorithm
#   private_key_pem = tls_private_key.syncthing[each.key].private_key_pem

#   subject {
#     common_name = "syncthing"
#   }
# }

# resource "tls_locally_signed_cert" "syncthing" {
#   for_each = var.syncthing_pods

#   cert_request_pem   = tls_cert_request.syncthing[each.key].cert_request_pem
#   ca_key_algorithm   = tls_private_key.syncthing-ca.algorithm
#   ca_private_key_pem = tls_private_key.syncthing-ca.private_key_pem
#   ca_cert_pem        = tls_self_signed_cert.syncthing-ca.cert_pem

#   validity_period_hours = 8760

#   allowed_uses = [
#     "key_encipherment",
#     "digital_signature",
#     "server_auth",
#     "client_auth",
#   ]
# }

# data "syncthing_device" "syncthing" {
#   for_each = var.syncthing_pods

#   cert_pem        = tls_locally_signed_cert.syncthing[each.key].cert_pem
#   private_key_pem = tls_private_key.syncthing[each.key].private_key_pem
# }

# resource "matchbox_group" "manifest-syncthing" {
#   profile = matchbox_profile.generic-profile.name
#   name    = "syncthing"
#   selector = {
#     manifest = "syncthing"
#   }

#   metadata = {
#     config = templatefile("${path.module}/../../templates/manifest/syncthing.yaml.tmpl", {
#       namespace = "default"

#       services         = var.services
#       networks         = var.networks
#       container_images = var.container_images
#       syncthing_path   = var.syncthing_path
#       syncthing_nodes = {
#         for k in keys(var.syncthing_pods) :
#         k => {
#           crt  = tls_locally_signed_cert.syncthing[k].cert_pem
#           key  = tls_private_key.syncthing[k].private_key_pem
#           id   = data.syncthing_device.syncthing[k].device_id
#           node = var.syncthing_pods[k].node
#         }
#       }
#     })
#   }
# }