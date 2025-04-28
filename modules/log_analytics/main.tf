variable "resource_prefix" {}
variable "location" {}
variable "resource_group" {}

resource "azurerm_log_analytics_workspace" "log" {
  name                = "${var.resource_prefix}-log"
  location            = var.location
  resource_group_name = var.resource_group
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

output "workspace_id" {
  value = azurerm_log_analytics_workspace.log.workspace_id
}

output "primary_key" {
  value = azurerm_log_analytics_workspace.log.primary_shared_key
}
