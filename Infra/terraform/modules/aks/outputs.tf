output "cluster_id" {
  value       = azurerm_kubernetes_cluster.aks.id
  description = "AKS cluster ID"
}

output "cluster_name" {
  value       = azurerm_kubernetes_cluster.aks.name
  description = "AKS cluster name"
}

output "kubelet_identity_object_id" {
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  description = "Kubelet identity object ID"
}
