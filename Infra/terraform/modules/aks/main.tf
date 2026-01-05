resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  workload_identity_enabled = var.workload_identity_enabled
  oidc_issuer_enabled       = var.oidc_issuer_enabled

  default_node_pool {
    name           = var.default_node_pool.name
    node_count     = var.default_node_pool.node_count
    vm_size        = var.default_node_pool.vm_size
    vnet_subnet_id = var.default_node_pool.vnet_subnet_id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    service_cidr   = var.network_profile.service_cidr
    dns_service_ip = var.network_profile.dns_service_ip
  }

  tags = var.tags
}
