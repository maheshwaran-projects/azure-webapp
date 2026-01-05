variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "server_name" {
  description = "SQL Server name"
  type        = string
}

variable "database_name" {
  description = "Database name"
  type        = string
}

variable "database_sku" {
  description = "Database SKU"
  type        = string
  default     = "Basic"
}

variable "server_version" {
  description = "SQL Server version"
  type        = string
  default     = "12.0"
}

variable "admin_username" {
  description = "Admin username"
  type        = string
}

variable "admin_password" {
  description = "Admin password"
  type        = string
  sensitive   = true
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = false
}

variable "aad_admin_username" {
  description = "AAD admin username"
  type        = string
  default     = "aad-sql-admin"
}

variable "aad_admin_object_id" {
  description = "AAD admin object ID"
  type        = string
}

variable "tenant_id" {
  description = "Tenant ID"
  type        = string
}

variable "tags" {
  description = "Tags for SQL resources"
  type        = map(string)
  default     = {}
}
