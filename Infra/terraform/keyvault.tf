# keyvault.tf
data "azurerm_client_config" "current" {}

# Reference the EXISTING Key Vault in rg-tfstate-prod
data "azurerm_key_vault" "secrets" {
  name                = "kv-quote-app"            # Your Key Vault name
  resource_group_name = "rg-tfstate-prod"         # Different resource group
}

# Read secrets from the existing Key Vault
data "azurerm_key_vault_secret" "appgw_certificate_base64" {
  name         = "appgw-certificate-base64"
  key_vault_id = data.azurerm_key_vault.secrets.id
}

data "azurerm_key_vault_secret" "appgw_cert_password" {
  name         = "appgw-cert-password"
  key_vault_id = data.azurerm_key_vault.secrets.id
}

data "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  key_vault_id = data.azurerm_key_vault.secrets.id
}

# Optional: Grant AKS access through a local Key Vault copy
resource "azurerm_key_vault" "local_for_aks" {
  count = var.create_local_key_vault ? 1 : 0

  name                = "kv-quote-aks-${random_id.rand.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  # Grant AKS identity access
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_kubernetes_cluster.aks.identity[0].principal_id

    secret_permissions = [
      "Get",
      "List"
    ]
  }

  # Grant yourself access for management
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete"
    ]
  }
}

# Copy SQL password to local KV for AKS access
resource "azurerm_key_vault_secret" "local_sql_password" {
  count = var.create_local_key_vault ? 1 : 0

  name         = "sql-admin-password"
  value        = data.azurerm_key_vault_secret.sql_admin_password.value
  key_vault_id = azurerm_key_vault.local_for_aks[0].id
  
  depends_on = [azurerm_key_vault.local_for_aks]
}
