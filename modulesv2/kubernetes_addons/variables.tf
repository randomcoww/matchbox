variable "networks" {
  type = any
}

variable "services" {
  type = any
}

variable "domains" {
  type = any
}

variable "container_images" {
  type = any
}

variable "apiserver_endpoint" {
  type = string
}

variable "ca_pem" {
  type = string
}

variable "cert_pem" {
  type = string
}

variable "private_key_pem" {
  type = string
}