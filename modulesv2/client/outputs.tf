output "templates" {
  value = {
    for host, params in var.hosts :
    host => [
      for template in var.templates :
      templatefile(template, {
        p                = params
        client_password  = var.client_password
        domains          = var.domains
        udev_steam_input = data.http.udev-60-steam-input.body
        udev_steam_vr    = data.http.udev-60-steam-vr.body
        wireguard_config = var.wireguard_config
        swap_device      = var.swap_device
        pulseaudio_server_networks = [
          "lan"
        ]
      })
    ]
  }
}