###############################################################################
# Key Vault
# Secret values are managed manually outside Terraform — IaC only manages
# the vault, the deployer's role assignment, and the private endpoint.
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
  public_network_access_enabled = true # Required for the deployer to manage secrets from outside the VNet
  rbac_authorization_enabled    = true
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
# Removed blocks — keep existing KV secrets in place but stop managing them.
# Run `terraform apply` to drop them from state without destroying the values.
###############################################################################
removed {
  from = azurerm_key_vault_secret.datacollector_storage
  lifecycle { destroy = false }
}

removed {
  from = azurerm_key_vault_secret.masterdata_storage
  lifecycle { destroy = false }
}

removed {
  from = azurerm_key_vault_secret.reporting_storage
  lifecycle { destroy = false }
}

removed {
  from = azurerm_key_vault_secret.servicebus
  lifecycle { destroy = false }
}

removed {
  from = azurerm_key_vault_secret.angelone_state_storage
  lifecycle { destroy = false }
}

removed {
  from = azurerm_key_vault_secret.alpacafe_storage
  lifecycle { destroy = false }
}

removed {
  from = azurerm_key_vault_secret.auth0_client_secret
  lifecycle { destroy = false }
}

removed {
  from = azurerm_key_vault_secret.auth0_secret
  lifecycle { destroy = false }
}

removed {
  from = azurerm_key_vault_secret.function_keys
  lifecycle { destroy = false }
}

removed {
  from = azurerm_key_vault_secret.placeholders
  lifecycle { destroy = false }
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
