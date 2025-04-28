variable "location" {
  description = "Ubicación del recurso"
  type        = string
}

variable "resource_group_name" {
  description = "Nombre del grupo de recursos"
  type        = string
}

variable "name_prefix" {
  description = "Prefijo para los nombres de recursos"
  type        = string
}

variable "app_name" {
  description = "Nombre de la aplicación del contenedor"
  type        = string
}

variable "image_tag" {
  description = "Etiqueta de la imagen en ACR"
  type        = string
}

variable "port" {
  description = "Puerto del contenedor"
  type        = number
}

variable "env_vars" {
  description = "Variables de entorno del contenedor"
  type        = map(string)
}
