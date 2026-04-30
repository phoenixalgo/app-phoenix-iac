variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "environment" { type = string }

variable "function_app_name" {
  description = "Short name for the function app (e.g. alpacadm, okxmgr)"
  type        = string
}

variable "app_service_plan_sku" {
  description = "Service Plan SKU (FC1 = Flex Consumption — required by this module)"
  type        = string
  default     = "FC1"
}

variable "deployment_storage_account_id" {
  description = "Resource ID of the storage account hosting the deployment container (for RBAC role assignment)"
  type        = string
}

variable "deployment_storage_blob_endpoint" {
  description = "Primary blob endpoint URL of the deployment storage account (e.g. https://<acct>.blob.core.windows.net/)"
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

variable "instance_memory_in_mb" {
  description = "Memory per instance in MB (Flex Consumption: 512, 2048, or 4096)"
  type        = number
  default     = 2048
}

variable "maximum_instance_count" {
  description = "Maximum number of concurrent instances Flex Consumption can scale to"
  type        = number
  default     = 40
}

variable "extra_app_settings" {
  description = "Additional app settings specific to this function app"
  type        = map(string)
  default     = {}
}
