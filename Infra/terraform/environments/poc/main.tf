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

}

provider "azurerm" {
  features {}
}

provider "random" {}

# Data sources
data "azurerm_client_config" "current" {}

data "azurerm_key_vault" "secrets" {
  name                = "kv-quote-app-vault"
  resource_group_name = "rg-tfstate-vault"
}

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

# Generate unique suffix
resource "random_id" "suffix" {
  byte_length = 4
}

# Local values
locals {
  environment = "poc"
  location    = "centralindia"
  rg_name     = "rg-quote-app-prod"
  
  common_tags = {
    Environment = local.environment
    Project     = "quote-app"
    ManagedBy   = "Terraform"
  }
  
  unique_suffix = random_id.suffix.hex
  
  # Resource names
  aks_cluster_name = "aks-quote-prod-${local.unique_suffix}"
  acr_name         = "quoteacr${local.unique_suffix}"
  sql_server_name  = "sql-quote-prod-${local.unique_suffix}"
  app_gateway_name = "appgw-prod-${local.unique_suffix}"
  key_vault_name   = "kv-quote-prod-${local.unique_suffix}"
}

# Modules
module "resource_group" {
  source = "../../modules/resource-group"
  
  name     = local.rg_name
  location = local.location
  tags     = local.common_tags
}

module "networking" {
  source = "../../modules/networking"
  
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  vnet_name           = "vnet-quote-app-prod"
  address_space       = ["10.10.0.0/16"]
  subnets = {
    aks = {
      address_prefixes = ["10.10.1.0/24"]
      service_endpoints = ["Microsoft.Sql", "Microsoft.KeyVault"]
    }
    sql = {
      address_prefixes = ["10.10.2.0/24"]
      service_endpoints = ["Microsoft.Sql"]
    }
    appgw = {
      address_prefixes = ["10.10.3.0/24"]
    }
  }
  tags = local.common_tags
}

module "acr" {
  source = "../../modules/acr"
  
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  name                = local.acr_name
  sku                 = "Standard"
  admin_enabled       = false
  tags                = local.common_tags
}

module "aks" {
  source = "../../modules/aks"
  
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  cluster_name        = local.aks_cluster_name
  dns_prefix          = "quoteaksprod"
  kubernetes_version  = "1.27"
  workload_identity_enabled = true
  oidc_issuer_enabled = true
  
  default_node_pool = {
    name           = "system"
    node_count     = 3
    vm_size        = "Standard_D2ls_v5"
    vnet_subnet_id = module.networking.subnet_ids["aks"]
  }
  
  tags = local.common_tags
}

module "sql" {
  source = "../../modules/sql"
  
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  server_name         = local.sql_server_name
  database_name       = "quotedb"
  database_sku        = "Basic"
  admin_username      = "sqladminuser"
  admin_password      = data.azurerm_key_vault_secret.sql_admin_password.value
  public_network_access_enabled = false
  aad_admin_object_id = data.azurerm_client_config.current.object_id
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = local.common_tags
}

module "app_gateway" {
  source = "../../modules/app-gateway"
  
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  name                = local.app_gateway_name
  sku_name            = "WAF_v2"
  sku_tier            = "WAF_v2"
  subnet_id           = module.networking.subnet_ids["appgw"]
  domain_name_label   = "quoteapp-prod"
  host_name           = "quoteapp.centralindia.cloudapp.azure.com"
  ssl_certificate_data = data.azurerm_key_vault_secret.appgw_certificate_base64.value
  ssl_certificate_password = data.azurerm_key_vault_secret.appgw_cert_password.value
  health_probe_host   = "quoteapp.centralindia.cloudapp.azure.com"
  tags                = local.common_tags
}

module "key_vault" {
  source = "../../modules/key-vault"
  
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  name                = local.key_vault_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  purge_protection_enabled = false
  soft_delete_retention_days = 7
  
  access_policies = [
    {
      tenant_id = data.azurerm_client_config.current.tenant_id
      object_id = data.azurerm_client_config.current.object_id
      secret_permissions = ["Get", "List", "Set", "Delete", "Recover"]
    },
    {
      tenant_id = data.azurerm_client_config.current.tenant_id
      object_id = module.aks.kubelet_identity_object_id
      secret_permissions = ["Get", "List"]
    }
  ]
  
  tags = local.common_tags
}
