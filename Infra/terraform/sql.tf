# sql.tf - REMOVED the data "azurerm_client_config" "current" {} line

resource "azurerm_mssql_server" "sql" {
  name                = "sql-quote-${random_id.rand.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  version             = "12.0"

  # SQL admin credentials from Key Vault (randomly generated)
  administrator_login          = "sqladminuser"
  administrator_login_password = data.azurerm_key_vault_secret.sql_admin_password.value

  # SECURITY: Disable public access
  public_network_access_enabled = false

  # Azure AD Admin (required for Managed Identity auth)
  # Now references the data block from keyvault.tf
  azuread_administrator {
    login_username = "aad-sql-admin"
    object_id      = data.azurerm_client_config.current.object_id
  }
}

resource "azurerm_mssql_database" "db" {
  name      = "quotedb"
  server_id = azurerm_mssql_server.sql.id
  sku_name  = "Basic"

  depends_on = [
    azurerm_mssql_server.sql
  ]

  # Prevents 404 LTR policy race condition
  long_term_retention_policy {
    weekly_retention  = "P0D"
    monthly_retention = "P0D"
    yearly_retention  = "P0D"
  }

  timeouts {
    create = "30m"
    read   = "10m"
  }
}
