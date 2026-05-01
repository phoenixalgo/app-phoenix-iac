###############################################################################
# General
###############################################################################
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. test, staging, prod)"
  type        = string
  default     = "test"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "australiaeast"
}

variable "project" {
  description = "Project name used in resource naming"
  type        = string
  default     = "phoenix"
}

###############################################################################
# Networking
###############################################################################
variable "vnet_address_space" {
  description = "VNet address space"
  type        = string
  default     = "10.0.0.0/16"
}

###############################################################################
# Compute SKUs
###############################################################################
variable "function_app_plan_sku" {
  description = "Service Plan SKU for Function Apps (FC1 = Flex Consumption — required for the function_app module)"
  type        = string
  default     = "FC1"
}

variable "frontend_app_plan_sku" {
  description = "App Service Plan SKU for the frontend (B1 is fine — publicly accessible)"
  type        = string
  default     = "B1"
}

###############################################################################
# Observability
###############################################################################
variable "enable_application_insights" {
  description = "Toggle Application Insights + Log Analytics Workspace. When false the resources are removed and the AI connection string is not set on any function app."
  type        = bool
  default     = true
}

###############################################################################
# Network isolation strategy
###############################################################################
variable "use_private_endpoints" {
  description = <<EOT
When true (default), use private endpoints for data storage, Key Vault, and the function apps — traffic stays on the Microsoft backbone via privatelink. Costs ~$7.30/PE/month (≈ 8 PEs in this stack).

When false, drop all PEs and rely on:
  • Service endpoints on the frontend + functions subnets (free, traffic still routed on Microsoft backbone)
  • network_rules / network_acls referencing those subnets on storage and Key Vault
  • IP restrictions on each function app limiting inbound to the frontend subnet
Result: no PE charges, same VNet-only data path, but the resources' public endpoints remain reachable (RBAC/SAS still gates them).
EOT
  type        = bool
  default     = true
}

variable "home_ip_cidr" {
  description = "Optional CIDR allowed to reach the function apps directly (e.g. for ad-hoc curl from a developer machine). Leave empty to disable. Only effective in service-endpoint mode — in PE mode public access is off and the rule is dormant."
  type        = string
  default     = "203.211.105.223/32"
}

###############################################################################
# External principals — additional users / SPNs / groups that need write access
# to the data storage account (e.g. utility scripts populating tables from a
# local machine). Object IDs only.
###############################################################################
variable "external_table_writers" {
  description = "Object IDs (users, service principals, groups) that need 'Storage Table Data Contributor' on the data storage account."
  type        = list(string)
  default     = ["ae3b797c-d0bb-45aa-b3d0-9bb206e3a803"]
}

###############################################################################
# Auth0 (set via tfvars or env — never commit secrets)
###############################################################################
variable "auth0_domain" {
  description = "Auth0 domain (e.g. myapp.au.auth0.com)"
  type        = string
  default     = ""
}

variable "auth0_client_id" {
  description = "Auth0 application client ID for the test environment"
  type        = string
  default     = ""
}

# auth0_client_secret and auth0_secret are managed directly in Key Vault — no Terraform variable.
