resource "azurerm_network_security_rule" "allow_ssh" {
  name                        = "${var.prefix}-ssh"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = var.allowed_ssh_cidr_blocks
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group
  network_security_group_name = var.nsg_name
}

resource "azurerm_network_security_rule" "allow_80" {
  name                        = "${var.prefix}-http-hashicups"
  priority                    = 302
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefixes     = var.allowed_http_cidr_blocks
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group
  network_security_group_name = var.nsg_name
}

# By default if the user doesn't disable it we create an asg
resource "azurerm_public_ip" "public_ip" {
  name                = "${var.prefix}-client-ip"
  location            = var.location
  resource_group_name = var.resource_group
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface" "client_nic" {
  name                = "${var.prefix}-client-nic"
  location            = var.location
  resource_group_name = var.resource_group

  ip_configuration {
    name                          = "${var.prefix}-ip-config"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "${var.prefix}-client-vm"
  location              = var.location
  resource_group_name   = var.resource_group
  size                  = "Standard_F2s_v2"
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.client_nic.id]

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
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }

  setup = base64encode(templatefile("${path.module}/templates/setup.sh", {
      consul_config    = var.client_config_file,
      consul_ca        = var.client_ca_file,
      consul_acl_token = var.root_token,
      consul_version   = var.consul_version,
      vpc_cidr         = var.vpc_cidr
      cts_version      = "0.5.2"

      cts_config = base64encode(templatefile("../cts-config-basic.hcl")),
      cts_vars = base64encode(templatefile("../cts-example-basic.tfvars"))
  }))
}
