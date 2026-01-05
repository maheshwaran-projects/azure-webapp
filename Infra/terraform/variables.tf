variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "centralindia"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "rg-quote-app"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
