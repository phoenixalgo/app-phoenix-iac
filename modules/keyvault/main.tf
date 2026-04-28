###############################################################################
# Key Vault
# Dev uses: HyblockKeyVault
###############################################################################
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                          = "kv-${var.project}-${var.environment}"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false
  public_network_access_enabled = true # Required for Terraform to seed secrets from outside VNet
  enable_rbac_authorization     = true
}

###############################################################################
# Grant the deployer (current user/SP) Key Vault Administrator role
###############################################################################
resource "azurerm_role_assignment" "deployer_kv_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

###############################################################################
# Seed secrets — mirrors the Key Vault secret names from dev (HyblockKeyVault)
# Actual secret values should be updated manually or via CI after first apply.
###############################################################################
resource "azurerm_key_vault_secret" "datacollector_storage" {
  name         = "hyblock-datacollector-storage-connection-string"
  value        = var.data_storage_connection_string
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.deployer_kv_admin]
}

resource "azurerm_key_vault_secret" "masterdata_storage" {
  name         = "hyblock-masterdata-connection-string"
  value        = var.data_storage_connection_string
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.deployer_kv_admin]
}

resource "azurerm_key_vault_secret" "reporting_storage" {
  name         = "hyblock-reporting-storage-connection-string"
  value        = var.data_storage_connection_string
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.deployer_kv_admin]
}

resource "azurerm_key_vault_secret" "servicebus" {
  name         = "hyblock-servicebus-connection-string"
  value        = var.servicebus_connection_string
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.deployer_kv_admin]
}

resource "azurerm_key_vault_secret" "angelone_state_storage" {
  name         = "angelone-state-storage-connection-string"
  value        = var.data_storage_connection_string
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.deployer_kv_admin]
}

###############################################################################
# Auth0 secrets (used by frontend via @Microsoft.KeyVault references)
###############################################################################
resource "azurerm_key_vault_secret" "auth0_client_secret" {
  name         = "auth0-client-secret"
  value        = var.auth0_client_secret
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.deployer_kv_admin]

  lifecycle {
    ignore_changes = [value]
  }
}

resource "azurerm_key_vault_secret" "auth0_secret" {
  name         = "auth0-secret"
  value        = var.auth0_secret
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.deployer_kv_admin]

  lifecycle {
    ignore_changes = [value]
  }
}

# Placeholder secrets — must be updated with real values after apply
locals {
  placeholder_secrets = {
    "ALPACA-API-KEY"                             = "REPLACE_ME"
    "ALPACA-API-SECRET"                          = "REPLACE_ME"
    "TELEGRAM-BOT-TOKEN"                         = "REPLACE_ME"
    "OKX-TRADESIGNAL-ACCOUNT1-API-KEY"           = "REPLACE_ME"
    "OKX-TRADESIGNAL-ACCOUNT1-API-SECRET"        = "REPLACE_ME"
    "OKX-TRADESIGNAL-ACCOUNT1-PASSPHRASE"        = "REPLACE_ME"
    "OKX-TRADESIGNAL-ACCOUNT2-API-KEY"           = "REPLACE_ME"
    "OKX-TRADESIGNAL-ACCOUNT2-API-SECRET"        = "REPLACE_ME"
    "OKX-TRADESIGNAL-ACCOUNT2-PASSPHRASE"        = "REPLACE_ME"
    "ANGELONE-API-KEY"                           = "REPLACE_ME"
    "ANGELONE-CLIENT-CODE"                       = "REPLACE_ME"
    "ANGELONE-MPIN"                              = "REPLACE_ME"
    "ANGELONE-TOTP-SECRET"                       = "REPLACE_ME"
    "hyblock-alpacafe-storage-connection-string"  = "REPLACE_ME"
  }
}

resource "azurerm_key_vault_secret" "placeholders" {
  for_each     = local.placeholder_secrets
  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.deployer_kv_admin]

  lifecycle {
    ignore_changes = [value]
  }
}

###############################################################################
# Private Endpoint
###############################################################################
resource "azurerm_private_endpoint" "keyvault" {
  name                = "pe-${var.project}-kv-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_pe_id

  private_service_connection {
    name                           = "psc-keyvault"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "kv-dns"
    private_dns_zone_ids = [var.private_dns_zone_vault_id]
  }
}
