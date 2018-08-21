### Terraform configs for provisioning homelab resources

Config rendering is handled by [CoreOS Matchbox](https://github.com/coreos/matchbox/).

#### Renderer

[Renderer](renderer) generates minimal configuration for standing up a local Matchbox server that accepts configuration from terraform.
This is used to generate configuration for provisioning the VM host and PXE boot environment VM needed for building all other services.

#### Packer

[Packer](packer) reads kickstart configuration generated by the renderer to build an image for the VM host. 
Image is used to provision hardware on the network before the network boot environment is available.

#### Provisioner

[Provisioner](provisioner) is the local Matchbox server with supporting services for a PXE boot environment. Config can be generated locally using the local renderer.
Currently, configs need to be commited to the repo path [static](static).

This remote URL is passed into Libvirt configuration [here](static/libvirt/provisioner-0.xml) to configure the server during startup.

#### Kubernetes cluster

Once all of the above is up, [Kubernetes PXE boot configs](kubernetes_cluster) can be generated on the new Matchbox server.