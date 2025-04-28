output "container_app_url" {
  value = azurerm_container_app.frontend.ingress[0].fqdn
}


output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}