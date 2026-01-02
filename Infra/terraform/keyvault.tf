# keyvault.tf - KEEP THIS DECLARATION
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                       = "kv-quote-${random_id.rand.hex}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  # Grant yourself full access
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Recover",
      "Backup",
      "Restore",
      "Purge"
    ]
  }

  # Grant AKS identity access to read secrets
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_kubernetes_cluster.aks.identity[0].principal_id

    secret_permissions = [
      "Get",
      "List"
    ]
  }

  tags = {
    environment = "production"
  }
}

# Generate random passwords
resource "random_password" "appgw_cert" {
  length           = 32
  special          = true
  override_special = "!@#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "sql_admin" {
  length           = 32
  special          = true
  override_special = "!@#$%&*()-_=+[]{}<>:?"
}

# Store generated passwords in Key Vault
resource "azurerm_key_vault_secret" "appgw_cert_password" {
  name         = "appgw-cert-password"
  value        = random_password.appgw_cert.result
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_key_vault.kv]
}

resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  value        = random_password.sql_admin.result
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_key_vault.kv]
}
