locals {
  manifests = [
    for k in compact([
      for j in flatten([
        for i in var.kubernetes_manifests :
        regexall("(?ms)$(.*?)^---", "${i}\n---")
      ]) :
      trimspace(j)
    ]) :
    yamldecode(k)
  ]

  namespaces_by_key = {
    for j in local.manifests :
    "${j.kind}-${lookup(j.metadata, "namespace", "default")}-${j.metadata.name}" => j
    if j.kind == "Namespace"
  }

  resources_by_key = {
    for j in local.manifests :
    "${j.kind}-${lookup(j.metadata, "namespace", "default")}-${j.metadata.name}" => j
    if j.kind != "Namespace"
  }

  # These are horrible hacks to workaround duplicate keys not allowed:
  # manifests = [
  #   for l in distinct([
  #     for k in compact([
  #       for j in flatten([
  #         for i in var.kubernetes_manifests :
  #         regexall( "(?ms)$(.*?)^---", "---\n${i}\n---" )
  #       ]) :
  #       trimspace(j)
  #     ]) :
  #     # cleanup and allow distinct to run
  #     yamlencode(yamldecode(k))
  #   ]) :
  #   yamldecode(l)
  # ]

  # manifests_by_key = {
  #   for k, v in transpose({
  #     for j in local.manifests :
  #     yamlencode(j) => ["${j.kind}-${lookup(j.metadata, "namespace", "default")}-${j.metadata.name}"]
  #   }) :
  #   k => yamldecode(v[0])
  # }
}

resource "kubernetes_manifest" "namespace" {
  provider = kubernetes-alpha

  for_each = local.namespaces_by_key
  manifest = each.value
}

resource "kubernetes_manifest" "resource" {
  provider = kubernetes-alpha

  for_each = local.resources_by_key
  manifest = each.value
}