resource "azurerm_public_ip" "appgw_pip" {
  name                = "pip-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = var.domain_name_label
  tags                = var.tags
}

resource "azurerm_application_gateway" "appgw" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  sku {
    name     = var.sku_name
    tier     = var.sku_tier
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = "https"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "public-frontend"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  backend_address_pool {
    name = "backend-pool"
  }

  backend_http_settings {
    name                  = "http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
    probe_name           = "health-probe"
  }

  probe {
    name                = "health-probe"
    protocol            = "Http"
    path                = var.health_probe_path
    host                = var.health_probe_host
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
  }

  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "public-frontend"
    frontend_port_name             = "https"
    protocol                       = "Https"
    ssl_certificate_name           = "ssl-certificate"
    host_name                      = var.host_name
  }

  request_routing_rule {
    name                       = "https-rule"
    rule_type                  = "Basic"
    http_listener_name         = "https-listener"
    backend_address_pool_name  = "backend-pool"
    backend_http_settings_name = "http-settings"
  }

  ssl_certificate {
    name     = "ssl-certificate"
    data     = var.ssl_certificate_data
    password = var.ssl_certificate_password
  }
}
