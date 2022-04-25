
resource "azurerm_public_ip" "gateway" {
  name                = var.name
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location
  allocation_method   = "Dynamic"
  sku                 = "Basic"
  tags                = var.tags
}

resource "azurerm_subnet" "gateway" {
  name                 = "${var.name}-gateway"
  resource_group_name  = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.test.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "local_file" "cts_tfvars_basic" {
  content  = <<EOT
name                            = "nia-testing"
azurerm_resource_group_name     = "${azurerm_resource_group.test.name}"
azurerm_resource_group_location = "${azurerm_virtual_network.test.location}"
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

resource "local_file" "cts_tfvars_path" {
  content  = <<EOT
name                            = "nia-testing"
azurerm_resource_group_name     = "${azurerm_resource_group.test.name}"
azurerm_resource_group_location = "${azurerm_virtual_network.test.location}"
azurerm_public_ip_id            = "${azurerm_public_ip.gateway.id}"
azurerm_service_subnet_id       = "${azurerm_subnet.gateway.id}"
private_ip_address_allocation   = "Dynamic"

enable_path_based_routing = true

frontend_port = 80
sku_name      = "Standard_Small"
sku_tier      = "Standard"

EOT
  filename = "../cts-example-path.tfvars"
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

resource "local_file" "cts_config_path" {
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
   path      = "/coffee/*"
 }
}

service {
 name = "product-public-api"
 cts_user_defined_meta = {
   path      = "/coffee/*"
 }
}

service {
 name = "payment-api"
 cts_user_defined_meta = {
   path      = "/checkout/*"
 }
}

service {
 name = "product-api"
 cts_user_defined_meta = {
   path      = "/coffee/*"
 }
}

service {
 name = "product-db"
 cts_user_defined_meta = {
   path      = "/coffee/*"
 }
}

task {
 name           = "testing"
 description    = "Example task with two services and path-based routing"
 providers      = ["azurerm"]
 source         = "../"
 services       = ["frontend", "product-public-api", "payment-api", "product-api", "product-db"]
 variable_files = ["cts-example-path.tfvars"]
}
EOT
  filename = "../cts-config-path.hcl"
}

# Step 3: Create a vm that is in the same subnet and runs CTS
module "vm_client" {

  depends_on = [local_file.cts_config_basic]
  source = "../../cts-vm"

  resource_group = azurerm_resource_group.rg.name
  location       = azurerm_resource_group.rg.location

  nsg_name                 = azurerm_network_security_group.nsg.name
  allowed_ssh_cidr_blocks  = ["0.0.0.0/0"]
  allowed_http_cidr_blocks = ["0.0.0.0/0"]
  subnet_id                = module.network.vnet_subnets[0]

  client_config_file = hcp_consul_cluster.main.consul_config_file
  client_ca_file     = hcp_consul_cluster.main.consul_ca_file
  root_token         = hcp_consul_cluster_root_token.token.secret_id
  consul_version     = hcp_consul_cluster.main.consul_version
}
