output "id" {
  value       = azurerm_container_registry.acr.id
  description = "ACR ID"
}

output "login_server" {
  value       = azurerm_container_registry.acr.login_server
  description = "ACR login server"
}
