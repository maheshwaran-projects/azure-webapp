resource "azurerm_mssql_server" "sql_server" {
  name                         = var.server_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = var.server_version
  administrator_login          = var.admin_username
  administrator_login_password = var.admin_password

  public_network_access_enabled = var.public_network_access_enabled

  azuread_administrator {
    login_username = var.aad_admin_username
    object_id      = var.aad_admin_object_id
    tenant_id      = var.tenant_id
  }

  tags = var.tags
}

resource "azurerm_mssql_database" "database" {
  name      = var.database_name
  server_id = azurerm_mssql_server.sql_server.id
  sku_name  = var.database_sku

  tags = var.tags

  timeouts {
    create = "30m"
    read   = "10m"
  }
}
