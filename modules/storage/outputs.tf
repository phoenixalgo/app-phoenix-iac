output "func_runtime_account_name" {
  value = azurerm_storage_account.func_runtime.name
}

output "func_runtime_account_id" {
  value = azurerm_storage_account.func_runtime.id
}

output "func_runtime_blob_endpoint" {
  description = "Primary blob endpoint of the function runtime storage account (used by Flex Consumption deployment)"
  value       = azurerm_storage_account.func_runtime.primary_blob_endpoint
}

output "data_account_name" {
  value = azurerm_storage_account.data.name
}

output "data_account_id" {
  value = azurerm_storage_account.data.id
}

output "data_primary_blob_endpoint" {
  value = azurerm_storage_account.data.primary_blob_endpoint
}
