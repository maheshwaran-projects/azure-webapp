# application_gateway.tf file
resource "azurerm_web_application_firewall_policy" "waf_policy" {
  name                = "wafpolicy-appgw"
  resource_group_name = var.resource_group_name
  location            = var.location

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  policy_settings {
    enabled                     = true
    mode                        = "Detection"  # Use "Prevention" for blocking mode
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }
}

resource "azurerm_application_gateway" "appgw" {
  name                = "appgw-prod"
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  # REMOVED: waf_configuration block - not needed when using firewall_policy_id
  # Only include the firewall_policy_id reference
  firewall_policy_id = azurerm_web_application_firewall_policy.waf_policy.id

  gateway_ip_configuration {
    name      = "appgw-ipcfg"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_port {
    name = "https-port"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "public-frontend"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  ########################
  # BACKEND (AKS ILB IP)
  ########################
  backend_address_pool {
    name         = "aks-ilb-backend"
    ip_addresses = ["10.224.0.6"]
  }

  backend_http_settings {
    name                  = "http-settings"
    protocol              = "Http"
    port                  = 80
    cookie_based_affinity = "Disabled"
    request_timeout       = 30
    probe_name            = "nginx-probe"
    host_name             = "quoteapp.centralindia.cloudapp.azure.com"
  }

  probe {
    name                = "nginx-probe"
    protocol            = "Http"
    path                = "/healthz"
    host                = "quoteapp.centralindia.cloudapp.azure.com"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
  }

  http_listener {
    name                           = "https-listener"
    frontend_ip_configuration_name = "public-frontend"
    frontend_port_name             = "https-port"
    protocol                       = "Https"
    ssl_certificate_name           = "appgw-cert"
    host_name                      = "quoteapp.centralindia.cloudapp.azure.com"
    require_sni                    = true
  }

  request_routing_rule {
    name                       = "route-to-aks"
    rule_type                  = "Basic"
    priority                   = 100
    http_listener_name         = "https-listener"
    backend_address_pool_name  = "aks-ilb-backend"
    backend_http_settings_name = "http-settings"
  }

  ssl_certificate {
    name     = "appgw-cert"
    data     = filebase64("C:/Users/arunagim/Desktop/cloudapp.pfx")
    password = azurerm_key_vault_secret.appgw_cert_password.value
  }

}


