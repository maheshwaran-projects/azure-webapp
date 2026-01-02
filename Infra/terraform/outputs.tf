# outputs.tf
output "key_vault_name" {
  value       = data.azurerm_key_vault.secrets.name
  description = "Name of the Key Vault for secret management"
  sensitive   = false
}

output "key_vault_resource_group" {
  value       = data.azurerm_key_vault.secrets.resource_group_name
  description = "Resource group containing the Key Vault"
  sensitive   = false
}

output "key_vault_id" {
  value       = data.azurerm_key_vault.secrets.id
  description = "ID of the Key Vault"
  sensitive   = false
}

output "sql_server_name" {
  value       = azurerm_mssql_server.sql.name
  description = "Name of the SQL Server"
  sensitive   = false
}

output "sql_admin_username" {
  value       = "sqladminuser"
  description = "SQL Server admin username"
  sensitive   = false
}

output "aks_cluster_name" {
  value       = azurerm_kubernetes_cluster.aks.name
  description = "Name of the AKS cluster"
  sensitive   = false
}

output "acr_name" {
  value       = azurerm_container_registry.acr.name
  description = "Name of the Container Registry"
  sensitive   = false
}

# Note: Passwords are NOT outputted to maintain security
# They are only accessible via Azure Key Vault
