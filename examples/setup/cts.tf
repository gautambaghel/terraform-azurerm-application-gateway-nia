# Azure data sources unfortunately rely on name, and resource group name which will never be computed
# fields since they are known input fields. This results in the terraform failing since the data
# source tries to look them up before they are actually created. In aws data sources take computed
# and randomized unique names so we never have this problem.
#
# To get around this we are using the id of the vnet and the subnet (which are computed fields)
# to look them up. The benefit of this is that Azure ids have a known structure (unlike aws ids)
# that is unlikely to ever change:
#
# /subscriptions/<subscription id>/resourceGroups/<resource group name>/providers/Microsoft.Network/virtualNetworks/<vnet name>
#
# Using this known structure we can trim the prefix after matching everything up to virtualNetworks/
data "azurerm_virtual_network" "vnet" {
  name                = trimprefix(module.network.vnet_id, regex(".*virtualNetworks\\/", module.network.vnet_id))
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_public_ip" "gateway" {
  name                = var.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"
  sku                 = "Basic"
  tags                = var.tags
}

resource "azurerm_subnet" "gateway" {
  name                 = "${var.name}-gateway"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.4.0/24"]
}

resource "local_file" "cts_tfvars_basic" {
  content  = <<EOT
name                            = "nia-testing"
azurerm_resource_group_name     = "${azurerm_resource_group.rg.name}"
azurerm_resource_group_location = "${azurerm_resource_group.rg.location}"
azurerm_public_ip_id            = "${azurerm_public_ip.gateway.id}"
azurerm_service_subnet_id       = "${azurerm_subnet.gateway.id}"
private_ip_address_allocation   = "Dynamic"

enable_path_based_routing = false

frontend_port = 80
sku_name      = "Standard_Small"
sku_tier      = "Standard"

EOT
  filename = "../cts-example-basic.tfvars"
}

resource "local_file" "cts_config_basic" {
  content  = <<EOT
log_level   = "DEBUG"
working_dir = "sync-tasks"
port        = 8558

syslog {}

buffer_period {
  enabled = true
  min     = "60s"
  max     = "240s"
}

consul {
  address = "${hcp_consul_cluster.main.consul_private_endpoint_url}"
  token   = "${hcp_consul_cluster_root_token.token.secret_id}"
}

driver "terraform" {
  log = true
  version = "1.0.0"

  backend "local" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.90"
    }
  }
}

terraform_provider "azurerm" {
  features {}
}

service {
 name = "frontend"
 cts_user_defined_meta = {
   host_name = "frontend.cts.hashicorp.com"
 }
}

service {
 name = "product-public-api"
 cts_user_defined_meta = {
   host_name = "product-public-api.cts.hashicorp.com"
 }
}

service {
 name = "payment-api"
 cts_user_defined_meta = {
   host_name = "payment-api.cts.hashicorp.com"
 }
}

service {
 name = "product-api"
 cts_user_defined_meta = {
   host_name = "product-api.cts.hashicorp.com"
 }
}

service {
 name = "product-db"
 cts_user_defined_meta = {
   host_name = "product-db.cts.hashicorp.com"
 }
}

task {
 name           = "testing"
 description    = "Example task with two services and basic routing"
 providers      = ["azurerm"]
 source         = "../"
 services       = ["frontend", "product-public-api", "payment-api", "product-api", "product-db"]
 variable_files = ["cts-example-basic.tfvars"]
}
EOT
  filename = "../cts-config-basic.hcl"
}

# Step 2: Create a vm and runs CTS
# resource "azurerm_public_ip" "public_ip" {
#   name                = "${var.prefix}-client-ip"
#   location              = azurerm_resource_group.rg.location
#   resource_group_name   = azurerm_resource_group.rg.name
#   allocation_method   = "Static"

#   tags = {
#     environment = "Production"
#   }
# }

# resource "azurerm_network_interface" "client_nic" {
#   name                = "${var.prefix}-client-nic"
#   location              = azurerm_resource_group.rg.location
#   resource_group_name   = azurerm_resource_group.rg.name

#   ip_configuration {
#     name                          = "${var.prefix}-ip-config"
#     subnet_id                     = module.network.vnet_subnets[0]
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.public_ip.id
#   }
# }

# resource "azurerm_linux_virtual_machine" "vm" {
#   name                  = "${var.prefix}-client-vm"
#   location              = azurerm_resource_group.rg.location
#   resource_group_name   = azurerm_resource_group.rg.name
#   size                  = "Standard_F2s_v2"
#   admin_username        = "adminuser"
#   network_interface_ids = [azurerm_network_interface.client_nic.id]

#   admin_ssh_key {
#     username   = "adminuser"
#     public_key = file("~/.ssh/id_rsa.pub")
#   }

#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }
#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "0001-com-ubuntu-server-focal"
#     sku       = "20_04-lts-gen2"
#     version   = "latest"
#   }
  
#   user_data = base64encode(templatefile("${path.module}/templates/user_data.sh", {
#     setup = base64gzip(templatefile("${path.module}/templates/setup.sh", {
#         arm_subscription_id = data.azurerm_subscription.current.subscription_id
#         arm_tenant_id       = data.azurerm_subscription.current.tenant_id
#         arm_client_id       = var.client_id
#         arm_client_secret   = var.client_secret

#         cts_version = var.cts_version
#         cts_config  = base64encode(local_file.cts_config_basic.content)
#         cts_vars    = base64encode(local_file.cts_tfvars_basic.content)
#     })),
#   }))
# }
