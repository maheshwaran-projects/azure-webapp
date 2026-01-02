terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-prod"
    storage_account_name = "tfstatequote525"
    container_name       = "tfstate"
    key                  = "quote-app/production.tfstate"
  }
}
