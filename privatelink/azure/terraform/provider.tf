terraform {
  required_providers {
    confluent = {
      source = "confluentinc/confluent"
      version = "1.4.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.55.0"
    }
  }
}

provider "confluent" {
  # Configuration options
}

provider "azurerm" {
  features {
  }
}
