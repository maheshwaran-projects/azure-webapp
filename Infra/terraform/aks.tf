# aks.tf - COMPATIBLE with your Terraform provider
resource "azurerm_kubernetes_cluster" "aks" {
  name                      = "aks-quote-app-ha"
  location                  = "centralindia"
  resource_group_name       = azurerm_resource_group.rg.name
  dns_prefix                = "quoteaks"
  workload_identity_enabled = true
  oidc_issuer_enabled       = true

  default_node_pool {
    name                = "system"
    node_count          = 3  # ✅ CHANGED FROM 1 TO 3 FOR HA
    vm_size             = "Standard_D2ls_v5"
    vnet_subnet_id      = azurerm_subnet.aks.id
    
    # ✅ CORRECT SYNTAX FOR AUTO-SCALING
    enable_auto_scaling   = true
    min_count            = 3
    max_count            = 10
    
    # ✅ ENABLE ZONES IF AVAILABLE (Check your region supports zones)
    # zones               = ["1", "2", "3"]  # Only if Central India has zones
  }

  identity {
    type = "SystemAssigned"
  }
  
  # ✅ NETWORK PROFILE - CORRECT SYNTAX
  network_profile {
    network_plugin     = "azure"
    network_policy     = "calico"
    dns_service_ip     = "10.0.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
    service_cidr       = "10.0.0.0/16"
    load_balancer_sku  = "standard"  # ✅ IMPORTANT FOR HA
  }
  
  # ✅ ADD FOR AUTOMATIC UPDATES (CORRECT SYNTAX)
  auto_scaler_profile {
    max_unready_percentage = 45
  }
}
