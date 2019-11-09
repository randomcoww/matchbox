output "matchbox_rpc_endpoints" {
  value = {
    for k in keys(var.kvm_hosts) :
    k => "${var.kvm_hosts[k].network.host_tap_ip}:${var.services.renderer.ports.rpc}"
  }
}