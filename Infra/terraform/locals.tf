locals {
  common_tags = merge({
    Environment = var.environment
    Project     = "quote-app"
    ManagedBy   = "Terraform"
  }, var.tags)
  
  unique_suffix = random_id.suffix.hex
}
