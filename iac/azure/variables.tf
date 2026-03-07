variable "app_unique_id" {
  description = "Unique identifier used as a prefix for all resource names"
  type        = string
}

variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "azure_location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "base_domain_name" {
  description = "Base domain name for DNS zone (e.g. example.com). Zone: azure.{app_unique_id}.{base_domain_name}"
  type        = string
}
