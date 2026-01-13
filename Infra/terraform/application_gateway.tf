### application_gateway.tf file - ENHANCED FOR HA
resource "azurerm_web_application_firewall_policy" "waf_policy" {
  name                = "wafpolicy-appgw-ha"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  policy_settings {
    enabled                     = true
    mode                        = "Detection"  
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }
}

resource "azurerm_application_gateway" "appgw" {
  name                = "appgw-prod-ha"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  # ✅ CRITICAL: ADD ZONE REDUNDANCY (SINGLE REGION HA)
  zones = ["1", "2", "3"]

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
#    capacity = 2  # Minimum for HA
  }

  # ✅ CRITICAL: ADD AUTO-SCALING
  autoscale_configuration {
    min_capacity = 2
    max_capacity = 10
  }

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

  backend_address_pool {
    name         = "aks-ilb-backend"
    ip_addresses = ["10.10.1.5"]
  }

  backend_http_settings {
    name                  = "http-settings"
    protocol              = "Http"
    port                  = 80
    cookie_based_affinity = "Disabled"
    request_timeout       = 30
    probe_name            = "nginx-probe"
    host_name             = "quoteapp.centralindia.cloudapp.azure.com"
    
    # ✅ ADD CONNECTION DRAINING
    connection_draining {
      enabled           = true
      drain_timeout_sec = 300
    }
  }

  probe {
    name                = "nginx-probe"
    protocol            = "Http"
    path                = "/healthz"
    host                = "quoteapp.centralindia.cloudapp.azure.com"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    
    # ✅ ADD MATCH CRITERIA
    match {
      status_code = ["200"]
    }
  }
  
  # ✅ ADD SECOND PROBE FOR APP HEALTH
  probe {
    name                = "app-health-probe"
    protocol            = "Http"
    path                = "/health"
    host                = "quoteapp.centralindia.cloudapp.azure.com"
    interval            = 60
    timeout             = 30
    unhealthy_threshold = 2
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
    data     = data.azurerm_key_vault_secret.appgw_certificate_base64.value
    password = data.azurerm_key_vault_secret.appgw_cert_password.value
  }
  
  # ✅ ADD SSL POLICY
  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }
  
  # ✅ ENABLE HTTP/2
  enable_http2 = true
}
