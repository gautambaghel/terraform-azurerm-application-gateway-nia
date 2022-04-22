resource "azurerm_network_interface" "web" {
  depends_on = [
    azurerm_subnet_network_security_group_association.test
  ]
  name                = "${var.name}-web"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.test.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web.id
  }
}

resource "azurerm_public_ip" "web" {
  name                = "${var.name}-web"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location
  allocation_method   = "Dynamic"

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "web" {
  depends_on          = [hcp_consul_cluster.main]
  name                = "${var.name}-web"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location
  tags                = var.tags
  size                = "Standard_F2"
  admin_username      = "adminuser"

  network_interface_ids = [
    azurerm_network_interface.web.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("scripts/web.sh", {
    CONSUL_SERVER      = replace(hcp_consul_cluster.main.consul_public_endpoint_url,"https://","")
    GOSSIP_KEY         = jsondecode(base64decode(hcp_consul_cluster.main.consul_config_file))["encrypt"]
    CA_PUBLIC_KEY      = base64decode(hcp_consul_cluster.main.consul_ca_file)
    BOOTSTRAP_TOKEN    = hcp_consul_cluster_root_token.token.secret_id
    DATACENTER         = hcp_consul_cluster.main.datacenter
    CONSUL_VERSION     = var.consul_version
    ENVOY_VERSION      = var.envoy_version
  }))
}
