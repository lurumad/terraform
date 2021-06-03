terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.60.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "terraform-rg"
    storage_account_name = "statesterraform"
    container_name       = "states"
    key                  = "webappcontainersprivatelink.tfstate"
  }
}

provider "azurerm" {
  features {}
}