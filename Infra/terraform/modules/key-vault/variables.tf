variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "name" {
  description = "Key Vault name"
  type        = string
}

variable "tenant_id" {
  description = "Tenant ID"
  type        = string
}

variable "sku_name" {
  description = "SKU name"
  type        = string
  default     = "standard"
}

variable "enabled_for_deployment" {
  description = "Enable for deployment"
  type        = bool
  default     = false
}

variable "enabled_for_disk_encryption" {
  description = "Enable for disk encryption"
  type        = bool
  default     = false
}

variable "enabled_for_template_deployment" {
  description = "Enable for template deployment"
  type        = bool
  default     = false
}

variable "purge_protection_enabled" {
  description = "Enable purge protection"
  type        = bool
  default     = false
}

variable "soft_delete_retention_days" {
  description = "Soft delete retention days"
  type        = number
  default     = 7
}

variable "access_policies" {
  description = "Access policies"
  type = list(object({
    tenant_id = string
    object_id = string
    key_permissions = optional(list(string), [])
    secret_permissions = optional(list(string), [])
    certificate_permissions = optional(list(string), [])
    storage_permissions = optional(list(string), [])
  }))
  default = []
}

variable "tags" {
  description = "Tags for Key Vault"
  type        = map(string)
  default     = {}
}
