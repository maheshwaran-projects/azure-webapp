# variables.tf
variable "location" {
  default = "Central India"
}

variable "resource_group_name" {
  default = "rg-quote-app"
}

variable "vnet_cidr" {
  default = "10.10.0.0/16"
}

# Add this variable
variable "create_local_key_vault" {
  description = "Create a local Key Vault copy for AKS to access secrets"
  type        = bool
  default     = false
}

variable "github_sp_client_id" {
  description = "Azure AD Application (Client ID) used by GitHub Actions OIDC"
  type        = string
}

