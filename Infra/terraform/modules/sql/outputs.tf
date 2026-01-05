output "server_id" {
  value       = azurerm_mssql_server.sql_server.id
  description = "SQL Server ID"
}

output "database_id" {
  value       = azurerm_mssql_database.database.id
  description = "Database ID"
}
