resource "azurerm_role_assignment" "aks_kubelet_acr_pull" {
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id

  depends_on = [
    azurerm_kubernetes_cluster.aks,
    azurerm_container_registry.acr
  ]
}

# role_assignment.tf - Add these resources
resource "azurerm_role_assignment" "aks_network_contributor_subnet" {
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  role_definition_name = "Network Contributor"
  scope                = azurerm_subnet.aks.id
  
  depends_on = [
    azurerm_kubernetes_cluster.aks,
    azurerm_subnet.aks
  ]
}

resource "azurerm_role_assignment" "aks_network_contributor_vnet" {
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  role_definition_name = "Network Contributor"
  scope                = azurerm_virtual_network.vnet.id
  
  depends_on = [
    azurerm_kubernetes_cluster.aks,
    azurerm_virtual_network.vnet
  ]
}

# Also add for the resource group (if needed)
resource "azurerm_role_assignment" "aks_contributor_rg" {
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  role_definition_name = "Contributor"
  scope                = azurerm_resource_group.rg.id
  
  depends_on = [
    azurerm_kubernetes_cluster.aks
  ]
}


resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azurerm_client_config.current.object_id
}

