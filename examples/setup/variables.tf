variable "location" {
  type        = string
  description = " The Azure Region where the Resource Group should exist. Changing this forces a new Resource Group to be created."
}

variable "name" {
  type        = string
  description = "The name for resources specific to testing this module"
}

variable "tags" {
  type        = map(string)
  description = "Tags for all testing resources in module"
  default = {
    Purpose = "E2E testing for terraform-azurerm-application-gateway-nia"
    owner   = "gautam@hashicorp.com"
  }
}

variable "consul_version" {
  type        = string
  description = "Consul version to install for example. Default is 1.11.5."
  default     = "1.11.5"
}

variable "envoy_version" {
  type        = string
  description = "Envoy version to install for example. Default is 1.20.2."
  default     = "1.20.2"
}

variable "network_region" {
  type        = string
  description = "the network region"
  default     = "West US 2"
}

variable "hvn_region" {
  type        = string
  description = "the hvn region"
  default     = "westus2"
}

variable "hvn_id" {
  type        = string
  description = "the hvn id"
  default     = "hvn-foobar"
}

variable "cluster_id" {
  type        = string
  description = "The cluster id is unique. All other unique values will be derived from this (resource group, vnet etc)"
  default     = "hcp-azure"
}

variable "tier" {
  type        = string
  description = "The HCP Consul tier to use when creating a Consul cluster"
  default     = "development"
}

variable "vnet_cidrs" {
  type        = list(string)
  description = "The ciders of the vnet. This should make sense with vnet_subnets"
  default     = ["10.0.0.0/16"]
}

variable "vnet_subnets" {
  type        = map(string)
  description = "The subnets associated with the vnet"
  default = {
    "subnet1" = "10.0.1.0/24",
    "subnet2" = "10.0.2.0/24",
    "subnet3" = "10.0.3.0/24",
  }
}

variable "prefix" {
  type        = string
  description = "Add a prefix to all resoures in module for uniqueness"
  default     = "vmclient-cts"
}

variable "cts_version" {
  type        = string
  description = "Consul Terraform Sync version"
  default = "0.5.2"
}

# variable "client_id" {
#   type        = string
#   description = "this is the azure client id"
#   sensitive = true
# }

# variable "client_secret" {
#   type        = string
#   description = "this is the azure client secret"
#   sensitive = true
# }