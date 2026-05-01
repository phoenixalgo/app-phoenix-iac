variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "environment" { type = string }
variable "project" { type = string }
variable "subnet_pe_id" { type = string }
variable "private_dns_zone_blob_id" { type = string }
variable "private_dns_zone_table_id" { type = string }

variable "use_private_endpoints" {
  description = "When false, skip the data storage PEs and add VNet subnet rules instead"
  type        = bool
  default     = true
}

variable "subnet_frontend_id" {
  description = "Frontend subnet ID — added to data storage network_rules in service-endpoint mode"
  type        = string
}

variable "subnet_functions_id" {
  description = "Functions subnet ID — added to data storage network_rules in service-endpoint mode"
  type        = string
}

variable "external_table_writers" {
  description = "Object IDs that get 'Storage Table Data Contributor' on the data storage account"
  type        = list(string)
  default     = []
}
