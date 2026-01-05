output "vnet_id" {
  value       = azurerm_virtual_network.vnet.id
  description = "Virtual network ID"
}

output "vnet_name" {
  value       = azurerm_virtual_network.vnet.name
  description = "Virtual network name"
}

output "subnet_ids" {
  value       = { for k, subnet in azurerm_subnet.subnets : k => subnet.id }
  description = "Subnet IDs"
}
