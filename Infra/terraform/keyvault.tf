############################################
# Client / Tenant Info
############################################
# Used to identify the GitHub OIDC / Terraform identity
data "azurerm_client_config" "current" {}

############################################
# Reference EXISTING (Central) Key Vault
############################################
# This Key Vault already exists and stores shared / infra secrets
data "azurerm_key_vault" "secrets" {
  name                = "kv-quote-app-vault"
  resource_group_name = "rg-tfstate-vault"
}

############################################
resource "azurerm_key_vault_access_policy" "terraform_read" {
  key_vault_id = data.azurerm_key_vault.secrets.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

############################################
data "azurerm_key_vault_secret" "appgw_certificate_base64" {
  name         = "appgw-certificate-base64"
  key_vault_id = data.azurerm_key_vault.secrets.id

  depends_on = [
    azurerm_key_vault_access_policy.terraform_read
  ]
}

data "azurerm_key_vault_secret" "appgw_cert_password" {
  name         = "appgw-cert-password"
  key_vault_id = data.azurerm_key_vault.secrets.id

  depends_on = [
    azurerm_key_vault_access_policy.terraform_read
  ]
}

data "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  key_vault_id = data.azurerm_key_vault.secrets.id

  depends_on = [
    azurerm_key_vault_access_policy.terraform_read
  ]
}

