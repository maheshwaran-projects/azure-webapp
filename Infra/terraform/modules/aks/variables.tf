variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "cluster_name" {
  description = "AKS cluster name"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for AKS"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.27"
}

variable "workload_identity_enabled" {
  description = "Enable workload identity"
  type        = bool
  default     = true
}

variable "oidc_issuer_enabled" {
  description = "Enable OIDC issuer"
  type        = bool
  default     = true
}

variable "default_node_pool" {
  description = "Default node pool configuration"
  type = object({
    name           = string
    node_count     = number
    vm_size        = string
    vnet_subnet_id = string
  })
}

variable "network_profile" {
  description = "Network profile configuration"
  type = object({
    service_cidr   = string
    dns_service_ip = string
  })
  default = {
    service_cidr   = "10.0.0.0/16"
    dns_service_ip = "10.0.0.10"
  }
}

variable "tags" {
  description = "Tags for AKS resources"
  type        = map(string)
  default     = {}
}
