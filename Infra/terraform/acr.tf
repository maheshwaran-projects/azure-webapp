##
resource "azurerm_container_registry" "acr" {
  name                = "quoteacr${random_id.rand.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  admin_enabled       = false
}

resource "random_id" "rand" {
  byte_length = 4
}






