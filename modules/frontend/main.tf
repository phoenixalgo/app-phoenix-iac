###############################################################################
# App Service Plan — frontend (public, B1 is sufficient)
###############################################################################
resource "azurerm_service_plan" "frontend" {
  name                = "asp-${var.project}-frontend-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.app_plan_sku
}

###############################################################################
# Managed Identity — used for ACR pull + Key Vault secret references
###############################################################################
resource "azurerm_user_assigned_identity" "frontend" {
  name                = "mi-${var.project}-frontend-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.frontend.principal_id
}

resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.frontend.principal_id
}

###############################################################################
# App Service — Next.js frontend (Docker container via managed identity)
# All secrets resolved via @Microsoft.KeyVault() references — no plaintext.
###############################################################################
resource "azurerm_linux_web_app" "frontend" {
  name                = "app-${var.project}-fe-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.frontend.id

  virtual_network_subnet_id = var.subnet_frontend_id
  https_only                = true

  key_vault_reference_identity_id = azurerm_user_assigned_identity.frontend.id

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.frontend.id]
  }

  site_config {
    always_on              = true
    ftps_state             = "Disabled"
    minimum_tls_version    = "1.2"
    vnet_route_all_enabled = true

    container_registry_use_managed_identity       = true
    container_registry_managed_identity_client_id = azurerm_user_assigned_identity.frontend.client_id

    application_stack {
      docker_registry_url = "https://${var.acr_login_server}"
      docker_image_name   = "manualtrades-fe:latest"
    }

    # When home_ip_cidr is set, lock the public hostname down to that single
    # source. Auth0 is then a second gate behind a network allow-list. Empty
    # CIDR keeps the FE open and the default action stays Allow.
    ip_restriction_default_action = var.home_ip_cidr != "" ? "Deny" : "Allow"

    dynamic "ip_restriction" {
      for_each = var.home_ip_cidr != "" ? [1] : []
      content {
        name       = "AllowHomeIp"
        priority   = 100
        action     = "Allow"
        ip_address = var.home_ip_cidr
      }
    }
  }

  app_settings = {
    # Runtime
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "WEBSITES_PORT"                       = "3000"
    "PORT"                                = "3000"
    "NODE_ENV"                            = "production"

    # Backend API URLs (private DNS — resolved via VNet integration)
    # Function keys are stored in Key Vault — populate the KV secrets manually after deploy
    "API_BASE_URL"                  = var.api_base_url
    "API_FUNCTION_KEY"              = "@Microsoft.KeyVault(SecretUri=${var.key_vault_uri}secrets/alpacadm-function-key)"
    "MARKETREGIME_API_BASE_URL"     = var.marketregime_api_base_url
    "MARKETREGIME_API_FUNCTION_KEY" = "@Microsoft.KeyVault(SecretUri=${var.key_vault_uri}secrets/portfoliomgr-function-key)"
    "ANGELONE_API_BASE_URL"         = var.angelone_api_base_url
    "ANGELONE_FUNCTION_KEY"         = "@Microsoft.KeyVault(SecretUri=${var.key_vault_uri}secrets/angelonemgr-function-key)"

    # Service Bus — resolved from Key Vault
    "AZURE_SERVICE_BUS_CONNECTION_STRING"      = "@Microsoft.KeyVault(SecretUri=${var.key_vault_uri}secrets/hyblock-servicebus-connection-string)"
    "AZURE_SERVICE_BUS_QUEUE_NAME_HYPERLIQUID" = "manual_trades_fe"
    "AZURE_SERVICE_BUS_QUEUE_NAME_ALPACA"      = "alpaca_trades_fe"
    "AZURE_SERVICE_BUS_QUEUE_NAME_OKXSPOT"     = "okx_trades_fe"
    "AZURE_SERVICE_BUS_QUEUE_NAME_ANGELONE"    = "angelone_tradesignal_account1"

    # Auth0 — secrets resolved from Key Vault
    "AUTH0_BASE_URL"        = "https://app-${var.project}-fe-${var.environment}.azurewebsites.net"
    "AUTH0_ISSUER_BASE_URL" = "https://${var.auth0_domain}"
    "AUTH0_CLIENT_ID"       = var.auth0_client_id
    "AUTH0_CLIENT_SECRET"   = "@Microsoft.KeyVault(SecretUri=${var.key_vault_uri}secrets/auth0-client-secret)"
    "AUTH0_SECRET"          = "@Microsoft.KeyVault(SecretUri=${var.key_vault_uri}secrets/auth0-secret)"
  }

  depends_on = [
    azurerm_role_assignment.acr_pull,
    azurerm_role_assignment.kv_secrets_user,
  ]
}
