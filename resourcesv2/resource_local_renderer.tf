##
## local matchbox
##
resource "local_file" "matchbox-ca-pem" {
  content  = chomp(tls_self_signed_cert.ca["matchbox-ca"].cert_pem)
  filename = "output/local-renderer/ca.crt"
}

resource "local_file" "matchbox-private-key-pem" {
  content  = chomp(tls_private_key.cert["matchbox"].private_key_pem)
  filename = "output/local-renderer/server.key"
}

resource "local_file" "matchbox-cert-pem" {
  content  = chomp(tls_locally_signed_cert.cert["matchbox"].cert_pem)
  filename = "output/local-renderer/server.crt"
}

locals {
  ## Matchbox instance to write configs to
  ## This needs to be passed in by hostname (e.g. -var=renderer=kvm-0) for now
  ## Dynamic provider support might resolse this
  local_renderer = {
    endpoint        = "127.0.0.1:${local.services.local_renderer.ports.rpc}"
    cert_pem        = tls_locally_signed_cert.cert["matchbox-client"].cert_pem
    private_key_pem = tls_private_key.cert["matchbox-client"].private_key_pem
    ca_pem          = tls_self_signed_cert.ca["matchbox-ca"].cert_pem
  }
}