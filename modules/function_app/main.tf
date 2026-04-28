###############################################################################
# Reusable module — one instance per function app
# Creates: Function App, System Identity, VNet integration, Private Endpoint,
#          RBAC role assignments (Key Vault, Storage)
###############################################################################

locals {
  full_name = "func-${var.function_app_name}-${var.environment}"
}

###############################################################################
# Linux Function App — uses managed identity for storage (no access keys)
###############################################################################
resource "azurerm_linux_function_app" "this" {
  name                = local.full_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = var.app_service_plan_id

  storage_account_name          = var.storage_account_name
  storage_uses_managed_identity = true

  virtual_network_subnet_id = var.subnet_functions_id

  public_network_access_enabled = false
  https_only                    = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      python_version = var.python_version
    }
    vnet_route_all_enabled = true
    ftps_state             = "Disabled"
    minimum_tls_version    = "1.2"
  }

  app_settings = merge(
    {
      "FUNCTIONS_WORKER_RUNTIME"       = "python"
      "WEBSITE_VNET_ROUTE_ALL"         = "1"
      "KEY_VAULT_URL"                  = var.key_vault_uri
      "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    },
    var.extra_app_settings,
  )
}

###############################################################################
# RBAC — Key Vault Secrets User
###############################################################################
resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_function_app.this.identity[0].principal_id
}

###############################################################################
# RBAC — func runtime storage (AzureWebJobsStorage needs these roles)
###############################################################################
resource "azurerm_role_assignment" "storage_blob_owner" {
  scope                = var.func_storage_account_id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_linux_function_app.this.identity[0].principal_id
}

resource "azurerm_role_assignment" "storage_queue_contributor" {
  scope                = var.func_storage_account_id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_linux_function_app.this.identity[0].principal_id
}

resource "azurerm_role_assignment" "storage_table_contributor" {
  scope                = var.func_storage_account_id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = azurerm_linux_function_app.this.identity[0].principal_id
}

resource "azurerm_role_assignment" "storage_account_contributor" {
  scope                = var.func_storage_account_id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_linux_function_app.this.identity[0].principal_id
}

###############################################################################
# RBAC — data storage (blob + table access for application data)
###############################################################################
resource "azurerm_role_assignment" "data_blob_contributor" {
  scope                = var.data_storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_function_app.this.identity[0].principal_id
}

resource "azurerm_role_assignment" "data_table_contributor" {
  scope                = var.data_storage_account_id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = azurerm_linux_function_app.this.identity[0].principal_id
}

###############################################################################
# Private Endpoint (inbound — so only VNet resources can call this function)
###############################################################################
resource "azurerm_private_endpoint" "function" {
  name                = "pe-${local.full_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_pe_id

  private_service_connection {
    name                           = "psc-${var.function_app_name}"
    private_connection_resource_id = azurerm_linux_function_app.this.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "func-dns"
    private_dns_zone_ids = [var.private_dns_zone_websites_id]
  }
}
