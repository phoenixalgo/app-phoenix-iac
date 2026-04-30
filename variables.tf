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
