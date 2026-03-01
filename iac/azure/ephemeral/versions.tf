# Before running `terraform init`, create a state backend:
#
# Azure Blob Storage:
#   az group create --name <RESOURCE_GROUP> --location <LOCATION>
#   az storage account create --name <STORAGE_ACCOUNT> --resource-group <RESOURCE_GROUP> \
#     --location <LOCATION> --sku Standard_LRS
#   az storage container create --name tfstate --account-name <STORAGE_ACCOUNT>
#
# Then update the backend block below.

terraform {
  required_version = ">= 1.5"

  backend "azurerm" {
    resource_group_name  = "REPLACE_WITH_YOUR_RESOURCE_GROUP"
    storage_account_name = "REPLACE_WITH_YOUR_STORAGE_ACCOUNT"
    container_name       = "tfstate"
    key                  = "terraform/state/ephemeral/terraform.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}
