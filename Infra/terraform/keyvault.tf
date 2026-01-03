############################################
# Client / Tenant Info
############################################
data "azurerm_client_config" "current" {}

############################################
# Reference EXISTING Key Vault
############################################
data "azurerm_key_vault" "secrets" {
  name                = "kv-quote-app-vault"
  resource_group_name = "rg-tfstate-vault"
}

############################################
# Read secrets from existing Key Vault
############################################
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

############################################
# OPTIONAL: Local Key Vault for AKS
############################################
resource "azurerm_key_vault" "local_for_aks" {
  count = var.create_local_key_vault ? 1 : 0

  name                = "kv-quote-aks-${random_id.rand.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  ##########################################
  # AKS Managed Identity Access
  ##########################################
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_kubernetes_cluster.aks.identity[0].principal_id

    secret_permissions = [
      "Get",
      "List"
    ]
  }

  ##########################################
  # Admin (Current User)
  ##########################################
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

############################################
# External lookup for GitHub SP Object ID
############################################
data "external" "github_sp_object_id" {
  program = [
    "bash",
    "-c",
    <<EOF
OBJECT_ID=$(az ad sp show --id "${var.github_sp_client_id}" --query id -o tsv 2>/dev/null || echo "")
echo "{\"object_id\": \"$OBJECT_ID\"}"
EOF
  ]

  query = {
    client_id = var.github_sp_client_id
  }
}

############################################
# Grant GitHub Actions access to Key Vault
############################################
resource "azurerm_key_vault_access_policy" "github_actions" {
  key_vault_id = data.azurerm_key_vault.secrets.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.external.github_sp_object_id.result.object_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

############################################
# Copy SQL password to local Key Vault
############################################
resource "azurerm_key_vault_secret" "local_sql_password" {
  count = var.create_local_key_vault ? 1 : 0

  name         = "sql-admin-password"
  value        = data.azurerm_key_vault_secret.sql_admin_password.value
  key_vault_id = azurerm_key_vault.local_for_aks[0].id

  depends_on = [
    azurerm_key_vault.local_for_aks
  ]
}
