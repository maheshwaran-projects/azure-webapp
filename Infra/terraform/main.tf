# modules.tf - Main module orchestration
module "resource_group" {
  source = "./modules/resource-group"
  
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

module "networking" {
  source = "./modules/networking"
  
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  vnet_name           = "vnet-${local.name_prefix}"
  address_space       = var.network_config.vnet_address_space
  subnets             = var.network_config.subnet_configs
  tags                = local.common_tags
}

module "acr" {
  source = "./modules/acr"
  
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  name                = local.acr_name
  sku                 = var.acr_config.sku
  admin_enabled       = var.acr_config.admin_enabled
  tags                = local.common_tags
}

module "aks" {
  source = "./modules/aks"
  
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  cluster_name        = local.aks_cluster_name
  dns_prefix          = var.aks_config.dns_prefix
  kubernetes_version  = "1.27"
  
  default_node_pool = {
    name                = "system"
    node_count          = var.aks_config.node_count
    vm_size             = var.aks_config.vm_size
    vnet_subnet_id      = module.networking.subnet_ids["aks"]
    enable_auto_scaling = var.aks_config.enable_auto_scaling
    min_count           = var.aks_config.min_count
    max_count           = var.aks_config.max_count
    os_disk_size_gb     = 128
    type                = "VirtualMachineScaleSets"
    zones               = ["1", "2", "3"]
  }
  
  network_profile = {
    network_plugin = "azure"
    network_policy = "azure"
    service_cidr   = "10.0.0.0/16"
    dns_service_ip = "10.0.0.10"
  }
  
  workload_identity_enabled = var.aks_config.workload_identity_enabled
  oidc_issuer_enabled       = var.aks_config.oidc_issuer_enabled
  aad_admin_group_ids       = []
  tags                      = local.common_tags
  
  depends_on = [
    module.networking,
    module.acr
  ]
}

module "sql" {
  source = "./modules/sql"
  
  resource_group_name          = module.resource_group.name
  location                     = module.resource_group.location
  server_name                  = local.sql_server_name
  database_name                = var.sql_config.db_name
  admin_username               = "sqladminuser"
  admin_password               = data.azurerm_key_vault_secret.sql_admin_password.value
  database_sku                 = var.sql_config.sku_name
  server_version               = "12.0"
  public_network_access_enabled = !var.sql_config.enable_private_endpoint
  subnet_id                    = module.networking.subnet_ids["sql"]
  enable_private_endpoint      = var.sql_config.enable_private_endpoint
  tags                         = local.common_tags
  
  depends_on = [
    module.networking
  ]
}

module "app_gateway" {
  source = "./modules/app-gateway"
  
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  name                = local.app_gateway_name
  sku_name            = var.app_gateway_config.sku_name
  sku_tier            = var.app_gateway_config.sku_tier
  min_capacity        = var.app_gateway_config.min_capacity
  max_capacity        = var.app_gateway_config.max_capacity
  zones               = var.app_gateway_config.zones
  subnet_id           = module.networking.subnet_ids["appgw"]
  enable_waf          = var.app_gateway_config.enable_waf
  waf_mode            = var.app_gateway_config.waf_mode
  host_name           = local.domain_name
  domain_name_label   = "quoteapp-${var.environment}"
  ssl_certificate_data = data.azurerm_key_vault_secret.appgw_certificate_base64.value
  ssl_certificate_password = data.azurerm_key_vault_secret.appgw_cert_password.value
  enable_http2        = var.app_gateway_config.enable_http2
  tags                = local.common_tags
  
  depends_on = [
    module.networking
  ]
}

module "key_vault" {
  source = "./modules/key-vault"
  
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  name                = "kv-${local.name_prefix}-${local.unique_suffix}"
  sku_name            = "standard"
  enable_rbac_authorization = false
  purge_protection_enabled = false
  soft_delete_retention_days = 7
  
  access_policies = [
    {
      tenant_id = data.azurerm_client_config.current.tenant_id
      object_id = data.azurerm_client_config.current.object_id
      secret_permissions = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"]
    },
    {
      tenant_id = data.azurerm_client_config.current.tenant_id
      object_id = module.aks.kubelet_identity_object_id
      secret_permissions = ["Get", "List"]
    }
  ]
  
  tags = local.common_tags
  
  depends_on = [
    module.aks
  ]
}

# Data sources for existing resources
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
