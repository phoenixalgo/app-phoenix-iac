###############################################################################
# Storage Account — Function App runtime + Flex Consumption deployment packages
###############################################################################
resource "azurerm_storage_account" "func_runtime" {
  name                            = "st${var.project}func${var.environment}"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  public_network_access_enabled   = true # Required for function app runtime
  allow_nested_items_to_be_public = false
}

# Note: deployment containers are per-function-app and live inside the
# function_app module (modules/function_app/main.tf) — Flex Consumption
# requires each app to have its own container.

###############################################################################
# Storage Account — Data (tables + blobs)
# Mirrors dev accounts: hyblockstatedev, hyblockdevaumaster, hyblockreportingdev
# Consolidated into one account for test to reduce cost.
###############################################################################
resource "azurerm_storage_account" "data" {
  name                            = "st${var.project}data${var.environment}"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  public_network_access_enabled   = true # Required for Terraform to create tables/containers from outside VNet
  allow_nested_items_to_be_public = false

  # Service-endpoint mode (use_private_endpoints = false): formally bind the
  # frontend + functions subnets so VNet traffic to this account routes via SE
  # on the Microsoft backbone. default_action stays Allow so Terraform / the
  # deployer can still manage tables and containers from outside the VNet.
  dynamic "network_rules" {
    for_each = var.use_private_endpoints ? [] : [1]
    content {
      default_action             = "Allow"
      bypass                     = ["AzureServices"]
      virtual_network_subnet_ids = [var.subnet_frontend_id, var.subnet_functions_id]
    }
  }
}

###############################################################################
# Blob Containers
###############################################################################
resource "azurerm_storage_container" "trade_screenshots" {
  name                  = "trade-screenshots"
  storage_account_id    = azurerm_storage_account.data.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "gym_screenshots" {
  name                  = "gym-screenshots"
  storage_account_id    = azurerm_storage_account.data.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "alpacaohlcdata" {
  name                  = "alpacaohlcdata"
  storage_account_id    = azurerm_storage_account.data.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "okxohlcdata" {
  name                  = "okxohlcdata"
  storage_account_id    = azurerm_storage_account.data.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "alpaca_data" {
  name                  = "alpaca-data"
  storage_account_id    = azurerm_storage_account.data.id
  container_access_type = "private"
}

###############################################################################
# Table Storage
# Tables are created by the function apps on first write, but we can
# pre-create them so deploys are idempotent.
###############################################################################
resource "azurerm_storage_table" "trade_journal" {
  name                 = "TradeJournal"
  storage_account_name = azurerm_storage_account.data.name
}

resource "azurerm_storage_table" "daily_routine_journal" {
  name                 = "DailyRoutineJournal"
  storage_account_name = azurerm_storage_account.data.name
}

resource "azurerm_storage_table" "okx_trade_schedules" {
  name                 = "OkxTradeSchedules"
  storage_account_name = azurerm_storage_account.data.name
}

resource "azurerm_storage_table" "angelone_execution_state" {
  name                 = "AngelOneExecutionState"
  storage_account_name = azurerm_storage_account.data.name
}

resource "azurerm_storage_table" "market_regime_score" {
  name                 = "MarketRegimeScore"
  storage_account_name = azurerm_storage_account.data.name
}

###############################################################################
# RBAC — additional users / SPNs that need to write to the data tables.
# Used by utility scripts running locally with az login (see e.g.
# C:\Users\rohit\python\dev\utilityscripts\market_regime.py).
###############################################################################
resource "azurerm_role_assignment" "external_table_writer" {
  for_each             = toset(var.external_table_writers)
  scope                = azurerm_storage_account.data.id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = each.value
}

###############################################################################
# Private Endpoints — Data storage (blob + table). Skipped when
# use_private_endpoints = false (saves ~$15/month for the two PEs).
###############################################################################
resource "azurerm_private_endpoint" "data_blob" {
  count               = var.use_private_endpoints ? 1 : 0
  name                = "pe-${var.project}-data-blob-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_pe_id

  private_service_connection {
    name                           = "psc-data-blob"
    private_connection_resource_id = azurerm_storage_account.data.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob-dns"
    private_dns_zone_ids = [var.private_dns_zone_blob_id]
  }
}

resource "azurerm_private_endpoint" "data_table" {
  count               = var.use_private_endpoints ? 1 : 0
  name                = "pe-${var.project}-data-table-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_pe_id

  private_service_connection {
    name                           = "psc-data-table"
    private_connection_resource_id = azurerm_storage_account.data.id
    subresource_names              = ["table"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "table-dns"
    private_dns_zone_ids = [var.private_dns_zone_table_id]
  }
}
