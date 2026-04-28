output "func_runtime_account_name" {
  value = azurerm_storage_account.func_runtime.name
}

output "func_runtime_account_id" {
  value = azurerm_storage_account.func_runtime.id
}

output "data_connection_string" {
  description = "Data storage connection string — only used for Key Vault seeding"
  value       = azurerm_storage_account.data.primary_connection_string
  sensitive   = true
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
