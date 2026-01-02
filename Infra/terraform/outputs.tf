# outputs.tf
output "key_vault_name" {
  value       = azurerm_key_vault.kv.name
  description = "Name of the Key Vault for secret management"
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

# Note: Passwords are NOT outputted to maintain security
# They are only accessible via Azure Key Vault
