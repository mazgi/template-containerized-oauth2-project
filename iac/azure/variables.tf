variable "app_unique_id" {
  description = "Unique identifier used as a prefix for all resource names"
  type        = string
  default     = "oauth2-app"
}

variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = ""
}

variable "azure_location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "azure_container_registry_name" {
  description = "Azure Container Registry name (must be globally unique, alphanumeric only)"
  type        = string
  default     = ""
}

variable "base_domain_name" {
  description = "Base domain name for DNS zone (e.g. example.com). Zone: azure.{app_unique_id}.{base_domain_name}"
  type        = string
}
