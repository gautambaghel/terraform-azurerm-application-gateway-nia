terraform {

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.90"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.14"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = ">= 0.26.0"
    }
  }

  required_version = ">= 1.0.11"

  provider_meta "hcp" {
    module_name = "hcp-consul"
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

provider "azuread" {
  tenant_id = var.tenant_id
}

provider "hcp" {
  client_id = var.hcp_client_id
  client_secret = var.hcp_client_secret
}

provider "consul" {
  address    = hcp_consul_cluster.main.consul_public_endpoint_url
  datacenter = hcp_consul_cluster.main.datacenter
  token      = hcp_consul_cluster_root_token.token.secret_id
}