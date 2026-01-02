# keyvault.tf
data "azurerm_client_config" "current" {}

# Use the existing Key Vault you created
resource "azurerm_key_vault" "kv" {
  name                = "kv-quote-155982b"  # Your existing Key Vault
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  # Grant yourself access (needed for Terraform to read)
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
}

# Read the Base64 certificate from Key Vault
data "azurerm_key_vault_secret" "appgw_certificate_base64" {
  name         = "appgw-certificate-base64"
  key_vault_id = azurerm_key_vault.kv.id
}

# Read the certificate password
data "azurerm_key_vault_secret" "appgw_cert_password" {
  name         = "appgw-cert-password"
  key_vault_id = azurerm_key_vault.kv.id
}

# Read SQL admin password
data "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  key_vault_id = azurerm_key_vault.kv.id
}
