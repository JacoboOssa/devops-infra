variable "resource_prefix" {}
variable "location" {}
variable "resource_group" {}
variable "acr_sku" {}

resource "azurerm_container_registry" "acr" {
  name                = "${var.resource_prefix}acr"
  location            = var.location
  resource_group_name = var.resource_group
  sku                 = var.acr_sku
  admin_enabled       = true
}

output "login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "username" {
  value = azurerm_container_registry.acr.admin_username
}

output "password" {
  value = azurerm_container_registry.acr.admin_password
}
