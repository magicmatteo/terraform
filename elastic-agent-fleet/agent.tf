resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.custom-tags
}

resource "azurerm_virtual_network" "main" {
  name                = "elastic-network"
  address_space       = ["10.220.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.custom-tags
}

resource "azurerm_subnet" "internal" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.220.2.0/24"]
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pub_ip.id
  }
  tags = var.custom-tags
}

data "http" "caller-ip" {
  url = "https://ifconfig.co/json"
  request_headers = {
    Accept = "application/json"
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-ssh-creator"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "${jsondecode(data.http.caller-ip.response_body).ip}/32"
    destination_address_prefix = "*"
  }
  tags = var.custom-tags
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_public_ip" "pub_ip" {
  name                = "${var.prefix}-ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"
  domain_name_label   = "${var.prefix}-${random_integer.hostname.id}"
  tags                = var.custom-tags
}
resource "random_password" "admin-password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
resource "random_integer" "hostname" {
  min = 10000
  max = 99999
}
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "azurerm_virtual_machine" "main" {
  name                             = "${var.prefix}-vm"
  location                         = azurerm_resource_group.rg.location
  resource_group_name              = azurerm_resource_group.rg.name
  network_interface_ids            = [azurerm_network_interface.main.id]
  vm_size                          = var.vm-size
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = "${var.prefix}-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }
  os_profile {
    computer_name  = var.prefix
    admin_username = var.agent-username
    admin_password = random_password.admin-password.result
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = tls_private_key.ssh_key.public_key_openssh
      path     = "/home/${var.agent-username}/.ssh/authorized_keys"
    }
  }
  connection {
    type        = "ssh"
    user        = var.agent-username
    private_key = tls_private_key.ssh_key.private_key_openssh
    host        = azurerm_public_ip.pub_ip.fqdn
  }
  provisioner "file" {
    when = create
    source      = "script.sh"
    destination = "/tmp/script.sh"
  }
  provisioner "remote-exec" {
    when = create
    inline = [
      "chmod +x /tmp/script.sh",
      "bash /tmp/script.sh ${var.fleet-url} ${var.enrolment-token}"
    ]
  }

  tags = var.custom-tags
}
resource "local_file" "private_key" {
  content              = tls_private_key.ssh_key.private_key_pem
  filename             = ".ssh/${var.prefix}.key"
  directory_permission = "0400"
  file_permission      = "0400"
}
output "ssh-connection-string" {
  description = "SSH connection string"
  value       = "ssh -i '.ssh/${var.prefix}.key' ${var.agent-username}@${azurerm_public_ip.pub_ip.fqdn}"
}
output "agent-fqdn" {
  description = "Agent FQDN"
  value       = azurerm_public_ip.pub_ip.fqdn
}