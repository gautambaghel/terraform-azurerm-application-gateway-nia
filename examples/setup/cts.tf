
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
  address = "${hcp_consul_cluster.main.consul_public_endpoint_url}"
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
 name = "api"
 cts_user_defined_meta = {
   host_name = "api.cts.hashicorp.com"
 }
}

service {
 name = "web"
 cts_user_defined_meta = {
   host_name = "web.cts.hashicorp.com"
 }
}

task {
 name           = "testing"
 description    = "Example task with two services and basic routing"
 providers      = ["azurerm"]
 source         = "../"
 services       = ["api", "web"]
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
  address = "${hcp_consul_cluster.main.consul_public_endpoint_url}"
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
 name = "api"
 cts_user_defined_meta = {
   path      = "/api/*"
 }
}

service {
 name = "web"
 cts_user_defined_meta = {
   path      = "/web/*"
 }
}

task {
 name           = "testing"
 description    = "Example task with two services and path-based routing"
 providers      = ["azurerm"]
 source         = "../"
 services       = ["api", "web"]
 variable_files = ["cts-example-path.tfvars"]
}
EOT
  filename = "../cts-config-path.hcl"
}
