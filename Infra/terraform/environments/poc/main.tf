terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-tfstate-vault"
    storage_account_name = "tfstatequote525"
    container_name       = "tfstate"
    key                  = "quote-app/production.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

provider "random" {}

module "quote_app" {
  source = "../../"

  environment = "production"
  location    = "centralindia"
  resource_group_name = "rg-quote-app-prod"

  tags = {
    CostCenter  = "IT"
    Department  = "Engineering"
    Application = "QuoteApp"
  }

  aks_config = {
    cluster_name    = "aks-quote-prod"
    dns_prefix      = "quoteaksprod"
    node_count      = 3
    vm_size         = "Standard_D2ls_v5"
    enable_auto_scaling = true
    min_count       = 3
    max_count       = 10
    workload_identity_enabled = true
    oidc_issuer_enabled = true
  }

  sql_config = {
    server_name   = "sql-quote-prod"
    db_name       = "quotedb"
    sku_name      = "S1"
    retention_days = 35
    enable_private_endpoint = true
  }

  app_gateway_config = {
    name          = "appgw-prod"
    sku_name      = "WAF_v2"
    sku_tier      = "WAF_v2"
    min_capacity  = 2
    max_capacity  = 10
    zones         = ["1", "2", "3"]
    enable_waf    = true
    waf_mode      = "Prevention"
    domain_name   = "quoteapp.centralindia.cloudapp.azure.com"
    enable_http2  = true
  }
}
