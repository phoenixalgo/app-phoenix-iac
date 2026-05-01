variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "environment" { type = string }
variable "project" { type = string }

variable "service_bus_connection_string" {
  description = "Service Bus namespace connection string with Send rights on the target queue."
  type        = string
  sensitive   = true
}

variable "target_queue_name" {
  description = "Queue the Logic App publishes incoming HTTP bodies to."
  type        = string
  default     = "hookdeck_tview-queue"
}

variable "concurrency_runs" {
  description = "Maximum concurrent trigger runs (Logic App runtimeConfiguration.concurrency.runs)."
  type        = number
  default     = 5
}
