###############################################################################
# Service Bus Namespace
# Dev uses: hyblockstandarddev (Standard tier)
###############################################################################
resource "azurerm_servicebus_namespace" "main" {
  name                          = "sb-${var.project}-${var.environment}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku                           = "Standard"
  public_network_access_enabled = false
  minimum_tls_version           = "1.2"
}

###############################################################################
# Shared Access Policy (mirrors dev tradesignalstopic_policy)
###############################################################################
resource "azurerm_servicebus_namespace_authorization_rule" "app_policy" {
  name         = "app-policy"
  namespace_id = azurerm_servicebus_namespace.main.id
  listen       = true
  send         = true
  manage       = false
}

###############################################################################
# Queues — complete inventory across all function apps
###############################################################################
locals {
  # Queues WITHOUT sessions
  standard_queues = [
    "alpaca_trades_fe",              # AlpacaDataManager: router from frontend
    "alpaca_breakout_fills",         # AlpacaDataManager: breakout processor
    "hookdeck_tview-queue",          # AlpacaDataManager: TradingView webhook relay
    "okx_trades_fe",                 # OkxManager: router from frontend
    "okx_long_trades_scheduler",     # OkxManager: scheduled trade processor
    "manual_trades_fe",              # PortfolioManager: router from frontend
    "angelone_execution_results",    # AngelOneManager: publishes results
  ]

  # Queues WITH sessions (ordered message processing per symbol)
  session_queues = [
    "alpaca_tradesignal_account1",       # AlpacaDataManager: executor
    "alpaca_tradesignal_autointents1",   # AlpacaDataManager: auto-intents
    "okx_tradesignal_account1",          # OkxManager: executor account 1
    "okx_tradesignal_account2",          # OkxManager: executor account 2
    "okx_tradesignal_autointents1",      # OkxManager: auto-intents
    "tradesignalqueue_account1",         # HyperLiquidManager: executor account 1
    "tradesignalqueue_account2",         # HyperLiquidManager: executor account 2
    "tradesignalqueue_account3",         # HyperLiquidManager: executor account 3
    "tradesignalqueue_account4",         # HyperLiquidManager: executor account 4
    "tradesignalqueue_account5",         # HyperLiquidManager: executor account 5
    "tradesignalqueue_remaining_symbols", # HyperLiquidManager: remaining symbols
    "hl_tradesignal_autointents1",       # HyperLiquidManager: auto-intents
    "angelone_tradesignal_account1",     # AngelOneManager: manual trades
    "angelone_tradesignal_autointents1", # AngelOneManager: auto-intents
    "ibkr_tradesignal_account1",         # IBKRManager: manual trades
    "ibkr_tradesignal_autointents1",     # IBKRManager: auto-intents
  ]
}

resource "azurerm_servicebus_queue" "standard" {
  for_each     = toset(local.standard_queues)
  name         = each.value
  namespace_id = azurerm_servicebus_namespace.main.id

  max_delivery_count          = 10
  lock_duration               = "PT1M"
  default_message_ttl         = "P14D"
  dead_lettering_on_message_expiration = true
}

resource "azurerm_servicebus_queue" "session" {
  for_each     = toset(local.session_queues)
  name         = each.value
  namespace_id = azurerm_servicebus_namespace.main.id

  requires_session            = true
  max_delivery_count          = 10
  lock_duration               = "PT5M"
  default_message_ttl         = "P14D"
  dead_lettering_on_message_expiration = true
}

###############################################################################
# Topics (PortfolioManager signal routing)
###############################################################################
locals {
  topics = [
    "trades_long_signals_topic",
    "trades_short_signals_topic",
    "trades_exit_signals_topic",
  ]
}

resource "azurerm_servicebus_topic" "topics" {
  for_each     = toset(local.topics)
  name         = each.value
  namespace_id = azurerm_servicebus_namespace.main.id

  default_message_ttl = "P14D"
}

###############################################################################
# Private Endpoint
###############################################################################
resource "azurerm_private_endpoint" "servicebus" {
  name                = "pe-${var.project}-sb-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_pe_id

  private_service_connection {
    name                           = "psc-servicebus"
    private_connection_resource_id = azurerm_servicebus_namespace.main.id
    subresource_names              = ["namespace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "sb-dns"
    private_dns_zone_ids = [var.private_dns_zone_servicebus_id]
  }
}
