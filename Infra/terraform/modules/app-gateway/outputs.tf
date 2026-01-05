output "id" {
  value       = azurerm_application_gateway.appgw.id
  description = "Application Gateway ID"
}

output "public_ip_address" {
  value       = azurerm_public_ip.appgw_pip.ip_address
  description = "Public IP address"
}
