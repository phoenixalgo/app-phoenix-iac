variable "enabled" {
  description = "Master toggle — when false the workspace and AI component are not created"
  type        = bool
}

variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "environment" { type = string }
variable "project" { type = string }

variable "retention_in_days" {
  description = "Log Analytics retention window"
  type        = number
  default     = 30
}
