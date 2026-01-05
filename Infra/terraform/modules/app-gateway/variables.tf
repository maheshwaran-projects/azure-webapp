variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "name" {
  description = "Application Gateway name"
  type        = string
}

variable "sku_name" {
  description = "SKU name"
  type        = string
  default     = "WAF_v2"
}

variable "sku_tier" {
  description = "SKU tier"
  type        = string
  default     = "WAF_v2"
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "domain_name_label" {
  description = "Domain name label"
  type        = string
}

variable "host_name" {
  description = "Host name"
  type        = string
}

variable "ssl_certificate_data" {
  description = "SSL certificate data (base64)"
  type        = string
  sensitive   = true
}

variable "ssl_certificate_password" {
  description = "SSL certificate password"
  type        = string
  sensitive   = true
}

variable "health_probe_path" {
  description = "Health probe path"
  type        = string
  default     = "/"
}

variable "health_probe_host" {
  description = "Health probe host"
  type        = string
}

variable "tags" {
  description = "Tags for Application Gateway"
  type        = map(string)
  default     = {}
}
