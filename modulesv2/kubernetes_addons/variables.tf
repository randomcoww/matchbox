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

variable "secrets" {
  type = any
}

variable "syncthing_path" {
  type = string
}

variable "syncthing_pods" {
  type = any
}

variable "renderer" {
  type = map(string)
}