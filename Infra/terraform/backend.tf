terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-prod"
    storage_account_name = "tfstatequote525"
    container_name       = "tfstate"
    key                  = "quote-app/production.tfstate"
    use_azuread_auth     = true
    subscription_id      = "74c4f319-b9f6-4b4f-b910-b6bb2923cf97"
    tenant_id           = var.tenant_id
  }
}
