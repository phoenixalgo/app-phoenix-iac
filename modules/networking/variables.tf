variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "environment" { type = string }
variable "project" { type = string }
variable "vnet_address_space" { type = string }

variable "use_private_endpoints" {
  description = "When false, enable subnet service endpoints so traffic to storage/KV/SB/Web stays on the Microsoft backbone without per-PE charges."
  type        = bool
  default     = true
}
