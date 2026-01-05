variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "name" {
  description = "ACR name"
  type        = string
}

variable "sku" {
  description = "ACR SKU"
  type        = string
  default     = "Standard"
}

variable "admin_enabled" {
  description = "Enable admin user"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags for ACR"
  type        = map(string)
  default     = {}
}
