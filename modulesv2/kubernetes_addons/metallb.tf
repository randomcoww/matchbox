resource "kubernetes_namespace" "metallb-system" {
  metadata {
    name = "metallb-system"
    labels = {
      app = "metallb"
    }
  }
}

resource "kubernetes_config_map" "metallb-config" {
  metadata {
    name      = "config"
    namespace = "metallb-system"
  }
  data = {
    config = yamlencode({
      address-pools = [
        {
          name = "my-ip-space"
          protocol = "layer2"
          addresses = [
            "192.168.126.64/26"
          ]
        }
      ]
    })
  }
}