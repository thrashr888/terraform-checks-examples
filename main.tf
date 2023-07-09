terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.7.0"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.64.0"
    }
    google = {
      source = "hashicorp/google"
      version = "4.72.1"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "azurerm" {
  features {}
}

provider "google" {
  project     = "my-project-id"
  region      = "us-central1"
}
