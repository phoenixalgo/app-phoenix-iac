variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "environment" { type = string }
variable "project" { type = string }
variable "subnet_pe_id" { type = string }
variable "private_dns_zone_vault_id" { type = string }

variable "use_private_endpoints" {
  description = "When false, skip the Key Vault PE and add VNet subnet ACLs instead"
  type        = bool
  default     = true
}

variable "subnet_frontend_id" {
  description = "Frontend subnet ID — added to KV network_acls in service-endpoint mode"
  type        = string
}

variable "subnet_functions_id" {
  description = "Functions subnet ID — added to KV network_acls in service-endpoint mode"
  type        = string
}
