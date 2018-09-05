variable "default_user" {
  type = "string"
}

variable "password" {
  type = "string"
}

## desktop
variable "desktop_hosts" {
  type = "list"
}

variable "desktop_ips" {
  type = "list"
}

variable "desktop_if" {
  type = "string"
}

## ip ranges
variable "netmask" {
  type = "string"
}

## matchbox provisioning access
variable "renderer_endpoint" {
  type = "string"
}

variable "renderer_private_key_pem" {
  type = "string"
}

variable "renderer_cert_pem" {
  type = "string"
}

variable "renderer_ca_pem" {
  type = "string"
}