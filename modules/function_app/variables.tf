variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "environment" { type = string }

variable "function_app_name" {
  description = "Short name for the function app (e.g. alpacadm, okxmgr)"
  type        = string
}

variable "app_service_plan_id" {
  description = "ID of the shared App Service Plan"
  type        = string
}

variable "storage_account_name" {
  description = "Storage account for AzureWebJobsStorage"
  type        = string
}

variable "func_storage_account_id" {
  description = "Resource ID of the func runtime storage account (for RBAC)"
  type        = string
}

variable "data_storage_account_id" {
  description = "Resource ID of the data storage account (for RBAC)"
  type        = string
}

variable "subnet_functions_id" {
  description = "Subnet ID for VNet integration (outbound)"
  type        = string
}

variable "subnet_pe_id" {
  description = "Subnet ID for private endpoints (inbound)"
  type        = string
}

variable "private_dns_zone_websites_id" {
  description = "Private DNS zone ID for privatelink.azurewebsites.net"
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault resource ID for RBAC role assignment"
  type        = string
}

variable "key_vault_uri" {
  description = "Key Vault URI"
  type        = string
}

variable "python_version" {
  description = "Python runtime version"
  type        = string
  default     = "3.11"
}

variable "extra_app_settings" {
  description = "Additional app settings specific to this function app"
  type        = map(string)
  default     = {}
}
