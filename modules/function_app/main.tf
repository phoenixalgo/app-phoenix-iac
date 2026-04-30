###############################################################################
# Reusable module — one Flex Consumption function app per call.
# Creates: Function App, System Identity, VNet integration, Private Endpoint,
#          RBAC role assignments (Key Vault, deployment storage, data storage).
###############################################################################

locals {
  full_name = "func-${var.function_app_name}-${var.environment}"
}

###############################################################################
# Per-function App Service Plan (Flex Consumption requires 1:1 plan-to-app)
###############################################################################
resource "azurerm_service_plan" "this" {
  name                = "asp-${var.function_app_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.app_service_plan_sku
}

###############################################################################
# Per-function deployment container
# Each Flex Consumption app needs its OWN container — sharing one across
# multiple apps causes the last `func azure functionapp publish` to overwrite
# the package every app reads from.
###############################################################################
resource "azurerm_storage_container" "deployment" {
  name                  = "deploy-${var.function_app_name}"
  storage_account_id    = var.deployment_storage_account_id
  container_access_type = "private"
}

###############################################################################
# Linux Function App (Flex Consumption)
# Uses managed identity for deployment storage access — no connection strings.
###############################################################################
resource "azurerm_function_app_flex_consumption" "this" {
  name                = local.full_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.this.id

  storage_container_type      = "blobContainer"
  storage_container_endpoint  = "${var.deployment_storage_blob_endpoint}${azurerm_storage_container.deployment.name}"
  storage_authentication_type = "SystemAssignedIdentity"

  runtime_name    = "python"
  runtime_version = var.python_version

  instance_memory_in_mb  = var.instance_memory_in_mb
  maximum_instance_count = var.maximum_instance_count

  virtual_network_subnet_id     = var.subnet_functions_id
  public_network_access_enabled = false
  https_only                    = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    minimum_tls_version = "1.2"
  }

  # Flex Consumption manages FUNCTIONS_WORKER_RUNTIME, FUNCTIONS_EXTENSION_VERSION,
  # AzureWebJobsStorage, and SCM_DO_BUILD_DURING_DEPLOYMENT itself — they cannot
  # appear in app_settings or the create call returns 400.
  app_settings = merge(
    {
      "KEY_VAULT_URL" = var.key_vault_uri
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
  principal_id         = azurerm_function_app_flex_consumption.this.identity[0].principal_id
}

###############################################################################
# RBAC — deployment + runtime storage account
# Flex Consumption uses one storage account for both:
#   - deployment package (blob)             → Storage Blob Data Owner
#   - host system keys, locks, leases       → Storage Blob Data Owner (already)
#   - queue triggers internal state         → Storage Queue Data Contributor
#   - table-based bookkeeping               → Storage Table Data Contributor
# Without queue/table access the host fails to load system keys with a
# generic InternalServerError.
###############################################################################
resource "azurerm_role_assignment" "deployment_storage_owner" {
  scope                = var.deployment_storage_account_id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_function_app_flex_consumption.this.identity[0].principal_id
}

resource "azurerm_role_assignment" "deployment_storage_queue" {
  scope                = var.deployment_storage_account_id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_function_app_flex_consumption.this.identity[0].principal_id
}

resource "azurerm_role_assignment" "deployment_storage_table" {
  scope                = var.deployment_storage_account_id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = azurerm_function_app_flex_consumption.this.identity[0].principal_id
}

###############################################################################
# RBAC — data storage (blob + table access for application data)
###############################################################################
resource "azurerm_role_assignment" "data_blob_contributor" {
  scope                = var.data_storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_function_app_flex_consumption.this.identity[0].principal_id
}

resource "azurerm_role_assignment" "data_table_contributor" {
  scope                = var.data_storage_account_id
  role_definition_name = "Storage Table Data Contributor"
  principal_id         = azurerm_function_app_flex_consumption.this.identity[0].principal_id
}

###############################################################################
# Private Endpoint (inbound — VNet-only access)
###############################################################################
resource "azurerm_private_endpoint" "function" {
  name                = "pe-${local.full_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_pe_id

  private_service_connection {
    name                           = "psc-${var.function_app_name}"
    private_connection_resource_id = azurerm_function_app_flex_consumption.this.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "func-dns"
    private_dns_zone_ids = [var.private_dns_zone_websites_id]
  }
}
