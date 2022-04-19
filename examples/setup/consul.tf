resource "azurerm_network_interface" "consul" {
  depends_on = [
    azurerm_subnet_network_security_group_association.test
  ]
  name                = "${var.name}-consul"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.test.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.consul.id
  }
}

resource "azurerm_public_ip" "consul" {
  name                = "${var.name}-consul"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location
  allocation_method   = "Dynamic"

  tags = var.tags
}

resource "random_id" "gossip_key" {
  byte_length = 32
}

resource "random_uuid" "consul_bootstrap_token" {}

resource "azurerm_linux_virtual_machine" "consul" {
  name                = "${var.name}-consul"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location
  tags                = var.tags
  size                = "Standard_F2"
  admin_username      = "adminuser"

  network_interface_ids = [
    azurerm_network_interface.consul.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("./.ssh/id_rsa.pub")
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

  custom_data = base64encode(templatefile("scripts/consul.sh", {
    GOSSIP_KEY         = random_id.gossip_key.b64_std
    CA_PUBLIC_KEY      = tls_self_signed_cert.ca_cert.cert_pem
    SERVER_PUBLIC_KEY  = tls_locally_signed_cert.server_signed_cert.cert_pem
    SERVER_PRIVATE_KEY = tls_private_key.server_key.private_key_pem
    BOOTSTRAP_TOKEN    = random_uuid.consul_bootstrap_token.result
    CONSUL_VERSION     = var.consul_version
  }))
}