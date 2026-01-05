output "id" {
  value       = azurerm_key_vault.kv.id
  description = "Key Vault ID"
}

output "vault_uri" {
  value       = azurerm_key_vault.kv.vault_uri
  description = "Key Vault URI"
}
