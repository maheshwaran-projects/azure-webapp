variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "vnet_name" {
  description = "Virtual network name"
  type        = string
}

variable "address_space" {
  description = "Virtual network address space"
  type        = list(string)
}

variable "subnets" {
  description = "Subnet configurations"
  type = map(object({
    address_prefixes = list(string)
    service_endpoints = optional(list(string), [])
    create_nsg       = optional(bool, false)
  }))
  default = {}
}

variable "tags" {
  description = "Tags for networking resources"
  type        = map(string)
  default     = {}
}
