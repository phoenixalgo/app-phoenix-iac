###############################################################################
# Resource Group
###############################################################################
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project}-${var.environment}"
  location = var.location
  tags     = local.default_tags
}

###############################################################################
# Phase 1 — Networking (VNet, Subnets, NSGs, Private DNS Zones)
###############################################################################
module "networking" {
  source = "./modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  environment         = var.environment
  project             = var.project
  vnet_address_space  = var.vnet_address_space
}

###############################################################################
# Phase 2A — Storage Accounts, Blob Containers, Tables
###############################################################################
module "storage" {
  source = "./modules/storage"

  resource_group_name       = azurerm_resource_group.main.name
  location                  = var.location
  environment               = var.environment
  project                   = var.project
  subnet_pe_id              = module.networking.subnet_private_endpoints_id
  private_dns_zone_blob_id  = module.networking.private_dns_zone_ids["blob"]
  private_dns_zone_table_id = module.networking.private_dns_zone_ids["table"]
}

###############################################################################
# Phase 2B — Service Bus Namespace + All Queues + Topics
###############################################################################
module "servicebus" {
  source = "./modules/servicebus"

  resource_group_name            = azurerm_resource_group.main.name
  location                       = var.location
  environment                    = var.environment
  project                        = var.project
  subnet_pe_id                   = module.networking.subnet_private_endpoints_id
  private_dns_zone_servicebus_id = module.networking.private_dns_zone_ids["servicebus"]
}

###############################################################################
# Phase 2C — Key Vault (no seeding — secret values managed manually)
###############################################################################
module "keyvault" {
  source = "./modules/keyvault"

  resource_group_name       = azurerm_resource_group.main.name
  location                  = var.location
  environment               = var.environment
  project                   = var.project
  subnet_pe_id              = module.networking.subnet_private_endpoints_id
  private_dns_zone_vault_id = module.networking.private_dns_zone_ids["vault"]
}

###############################################################################
# Phase 2D — Container Registry (Basic, public)
###############################################################################
module "acr" {
  source = "./modules/acr"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  environment         = var.environment
  project             = var.project
}

###############################################################################
# Phase 3 — Function Apps (Flex Consumption)
# Each function app gets its own FC1 plan (Flex Consumption is 1 plan : 1 app).
# The plan is created inside the function_app module — see modules/function_app.
###############################################################################

###############################################################################
# Phase 3A — AlpacaDataManager
# Primary backend: journal, stats, tradegym, journal-routine, alerts, webhooks
# Source: C:\Users\rohit\python\functions\AlpacaDataManager
###############################################################################
module "func_alpacadatamanager" {
  source = "./modules/function_app"

  resource_group_name          = azurerm_resource_group.main.name
  location                     = var.location
  environment                  = var.environment
  function_app_name            = "alpacadm"
  app_service_plan_sku             = var.function_app_plan_sku
  deployment_storage_account_id    = module.storage.func_runtime_account_id
  deployment_storage_blob_endpoint = module.storage.func_runtime_blob_endpoint
  data_storage_account_id          = module.storage.data_account_id
  subnet_functions_id              = module.networking.subnet_functions_id
  subnet_pe_id                     = module.networking.subnet_private_endpoints_id
  private_dns_zone_websites_id     = module.networking.private_dns_zone_ids["websites"]
  key_vault_id                     = module.keyvault.vault_id
  key_vault_uri                    = module.keyvault.vault_uri

  extra_app_settings = {
    "AZURE_SERVICEBUS_CONNECTION_STRING" = "@Microsoft.KeyVault(SecretUri=${module.keyvault.vault_uri}secrets/hyblock-servicebus-connection-string)"
    "AZURE_STORAGE_CONNECTION"           = "@Microsoft.KeyVault(SecretUri=${module.keyvault.vault_uri}secrets/hyblock-datacollector-storage-connection-string)"
    "AZURE_MASTERDATA_CONNECTION"        = "@Microsoft.KeyVault(SecretUri=${module.keyvault.vault_uri}secrets/hyblock-masterdata-connection-string)"
    "AZURE_REPORTING_CONNECTION"         = "@Microsoft.KeyVault(SecretUri=${module.keyvault.vault_uri}secrets/hyblock-reporting-storage-connection-string)"
    "ALPACA_FE_STORAGE_CONNECTION"       = "@Microsoft.KeyVault(SecretUri=${module.keyvault.vault_uri}secrets/hyblock-alpacafe-storage-connection-string)"
  }
}

###############################################################################
# Phase 3B — PortfolioManager
# Serves: market-regime/dashboard, market-regime/components, market-regime/health
# Also: trade signal routing, hyperliquid-supported-symbols
# Source: C:\Users\rohit\python\functions\PortfolioManager
###############################################################################
module "func_portfoliomanager" {
  source = "./modules/function_app"

  resource_group_name          = azurerm_resource_group.main.name
  location                     = var.location
  environment                  = var.environment
  function_app_name            = "portfoliomgr"
  app_service_plan_sku             = var.function_app_plan_sku
  deployment_storage_account_id    = module.storage.func_runtime_account_id
  deployment_storage_blob_endpoint = module.storage.func_runtime_blob_endpoint
  data_storage_account_id          = module.storage.data_account_id
  subnet_functions_id              = module.networking.subnet_functions_id
  subnet_pe_id                     = module.networking.subnet_private_endpoints_id
  private_dns_zone_websites_id     = module.networking.private_dns_zone_ids["websites"]
  key_vault_id                     = module.keyvault.vault_id
  key_vault_uri                    = module.keyvault.vault_uri

  extra_app_settings = {
    "AZURE_SERVICEBUS_CONNECTION_STRING" = "@Microsoft.KeyVault(SecretUri=${module.keyvault.vault_uri}secrets/hyblock-servicebus-connection-string)"
    "AZURE_STORAGE_CONNECTION"           = "@Microsoft.KeyVault(SecretUri=${module.keyvault.vault_uri}secrets/hyblock-datacollector-storage-connection-string)"
    "AZURE_MASTERDATA_CONNECTION"        = "@Microsoft.KeyVault(SecretUri=${module.keyvault.vault_uri}secrets/hyblock-masterdata-connection-string)"
    "AZURE_REPORTING_CONNECTION"         = "@Microsoft.KeyVault(SecretUri=${module.keyvault.vault_uri}secrets/hyblock-reporting-storage-connection-string)"
  }
}

###############################################################################
# Phase 3C — OkxManager
# OKX spot trading via Service Bus queues + HTTP endpoints
# Source: C:\Users\rohit\python\functions\OkxManager
###############################################################################
module "func_okxmanager" {
  source = "./modules/function_app"

  resource_group_name          = azurerm_resource_group.main.name
  location                     = var.location
  environment                  = var.environment
  function_app_name            = "okxmgr"
  app_service_plan_sku             = var.function_app_plan_sku
  deployment_storage_account_id    = module.storage.func_runtime_account_id
  deployment_storage_blob_endpoint = module.storage.func_runtime_blob_endpoint
  data_storage_account_id          = module.storage.data_account_id
  subnet_functions_id              = module.networking.subnet_functions_id
  subnet_pe_id                     = module.networking.subnet_private_endpoints_id
  private_dns_zone_websites_id     = module.networking.private_dns_zone_ids["websites"]
  key_vault_id                     = module.keyvault.vault_id
  key_vault_uri                    = module.keyvault.vault_uri

  extra_app_settings = {
    "AZURE_SERVICEBUS_CONNECTION_STRING" = "@Microsoft.KeyVault(SecretUri=${module.keyvault.vault_uri}secrets/hyblock-servicebus-connection-string)"
    "AZURE_MASTERDATA_CONNECTION"        = "@Microsoft.KeyVault(SecretUri=${module.keyvault.vault_uri}secrets/hyblock-masterdata-connection-string)"
    "OKX_FE_QUEUE"                       = "okx_trades_fe"
    "OKX_Q_ACCOUNT1"                     = "okx_tradesignal_account1"
    "OKX_Q_ACCOUNT2"                     = "okx_tradesignal_account2"
    "OKX_AUTOINTENTS_QUEUE"              = "okx_tradesignal_autointents1"
    "OKX_MANAGED_ACCOUNTS"               = "tradesignal_account1,tradesignal_account2"
    "OKX_MAX_NOTIONAL_PCT"               = "10"
    "OKX_NEAR_BPS"                       = "5.0"
    "OKX_USE_PAPER"                      = "1" # Paper trading for test env
  }
}

###############################################################################
# Phase 3D — HyperLiquidManager
# Hyperliquid perp trading via Service Bus queues
# Source: C:\Users\rohit\python\functions\HyperLiquidManager
###############################################################################
module "func_hyperliquidmanager" {
  source = "./modules/function_app"

  resource_group_name          = azurerm_resource_group.main.name
  location                     = var.location
  environment                  = var.environment
  function_app_name            = "hlmgr"
  app_service_plan_sku             = var.function_app_plan_sku
  deployment_storage_account_id    = module.storage.func_runtime_account_id
  deployment_storage_blob_endpoint = module.storage.func_runtime_blob_endpoint
  data_storage_account_id          = module.storage.data_account_id
  subnet_functions_id              = module.networking.subnet_functions_id
  subnet_pe_id                     = module.networking.subnet_private_endpoints_id
  private_dns_zone_websites_id     = module.networking.private_dns_zone_ids["websites"]
  key_vault_id                     = module.keyvault.vault_id
  key_vault_uri                    = module.keyvault.vault_uri

  extra_app_settings = {
    "AZURE_SERVICEBUS_CONNECTION_STRING" = "@Microsoft.KeyVault(SecretUri=${module.keyvault.vault_uri}secrets/hyblock-servicebus-connection-string)"
    "AZURE_REPORTING_CONNECTION"         = "@Microsoft.KeyVault(SecretUri=${module.keyvault.vault_uri}secrets/hyblock-reporting-storage-connection-string)"
    "AZURE_MASTERDATA_CONNECTION"        = "@Microsoft.KeyVault(SecretUri=${module.keyvault.vault_uri}secrets/hyblock-masterdata-connection-string)"
  }
}

###############################################################################
# Phase 3E — AngelOneManager
# AngelOne Indian broker trading via Service Bus + HTTP
# Source: C:\Users\rohit\python\functions\AngelOneManager
###############################################################################
module "func_angelonemanager" {
  source = "./modules/function_app"

  resource_group_name          = azurerm_resource_group.main.name
  location                     = var.location
  environment                  = var.environment
  function_app_name            = "angelonemgr"
  app_service_plan_sku             = var.function_app_plan_sku
  deployment_storage_account_id    = module.storage.func_runtime_account_id
  deployment_storage_blob_endpoint = module.storage.func_runtime_blob_endpoint
  data_storage_account_id          = module.storage.data_account_id
  subnet_functions_id              = module.networking.subnet_functions_id
  subnet_pe_id                     = module.networking.subnet_private_endpoints_id
  private_dns_zone_websites_id     = module.networking.private_dns_zone_ids["websites"]
  key_vault_id                     = module.keyvault.vault_id
  key_vault_uri                    = module.keyvault.vault_uri

  extra_app_settings = {
    "AZURE_SERVICEBUS_CONNECTION_STRING"    = "@Microsoft.KeyVault(SecretUri=${module.keyvault.vault_uri}secrets/hyblock-servicebus-connection-string)"
    "ANGELONE_STATE_STORAGE_CONNECTION"     = "@Microsoft.KeyVault(SecretUri=${module.keyvault.vault_uri}secrets/angelone-state-storage-connection-string)"
    "ANGELONE_API_KEY"                      = "@Microsoft.KeyVault(SecretUri=${module.keyvault.vault_uri}secrets/ANGELONE-API-KEY)"
    "ANGELONE_CLIENT_CODE"                  = "@Microsoft.KeyVault(SecretUri=${module.keyvault.vault_uri}secrets/ANGELONE-CLIENT-CODE)"
    "ANGELONE_MPIN"                         = "@Microsoft.KeyVault(SecretUri=${module.keyvault.vault_uri}secrets/ANGELONE-MPIN)"
    "ANGELONE_TOTP_SECRET"                  = "@Microsoft.KeyVault(SecretUri=${module.keyvault.vault_uri}secrets/ANGELONE-TOTP-SECRET)"
    "ANGELONE_MANUAL_QUEUE_NAME"            = "angelone_tradesignal_account1"
    "ANGELONE_AUTOINTENTS_QUEUE_NAME"       = "angelone_tradesignal_autointents1"
    "ANGELONE_RESULTS_QUEUE_NAME"           = "angelone_execution_results"
    "ANGELONE_DRY_RUN"                      = "true" # Safety: dry run in test
    "ANGELONE_STATE_TABLE_NAME"             = "AngelOneExecutionState"
  }
}

###############################################################################
# Phase 4 — Frontend App Service (Next.js Docker container)
# Source: C:\Users\rohit\nextjs\manualtrades-fe
###############################################################################
module "frontend" {
  source = "./modules/frontend"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  environment         = var.environment
  project             = var.project
  app_plan_sku        = var.frontend_app_plan_sku

  subnet_frontend_id = module.networking.subnet_frontend_id

  acr_login_server = module.acr.login_server
  acr_id           = module.acr.id

  # Backend function app URLs (resolved via private DNS within VNet)
  api_base_url              = "https://${module.func_alpacadatamanager.default_hostname}/api"
  marketregime_api_base_url = "https://${module.func_portfoliomanager.default_hostname}/api"
  angelone_api_base_url     = "https://${module.func_angelonemanager.default_hostname}"

  # Key Vault (secrets resolved via @Microsoft.KeyVault references)
  key_vault_id  = module.keyvault.vault_id
  key_vault_uri = module.keyvault.vault_uri

  # Auth0 (non-secret values — secrets are in Key Vault)
  auth0_domain    = var.auth0_domain
  auth0_client_id = var.auth0_client_id
}
