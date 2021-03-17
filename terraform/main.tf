resource "azurerm_resource_group" "main" {
  name     = join("", [var.scenarioPrefix, "RG"])
  location = var.location
}

resource "random_string" "random" {
  length  = 4
  special = false
  upper = false
}

resource "azurerm_storage_account" "main" {
  name                     = join("", [var.StorageAccountName, random_string.random.result])
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "main" {
  name                  = var.FtpFileContainerName
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

resource "azurerm_public_ip" "main" {
  name                = join("", [var.scenarioPrefix, "PublicIp"])
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = var.publicIPAddressType
  domain_name_label   = var.dnsLabelPrefix
}

resource "azurerm_virtual_network" "main" {
  name                = join("", [var.scenarioPrefix, "Vnet"])
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.vnetAddressPrefix]
}

resource "azurerm_subnet" "main" {
  name                 = join("", [var.scenarioPrefix, "Subnet"])
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnetPrefix]
}

resource "azurerm_network_interface" "main" {
  name                = join("", [var.scenarioPrefix, "Nic"])
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

resource "tls_private_key" "ftp_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

output "tls_private_key" { 
  value = tls_private_key.ftp_ssh.private_key_pem 
  description = "Admin private SSH key."
  sensitive   = true
}

resource "random_password" "ftp_pwd" {
  length  = 16
  special = false
}

output "ftp_pwd" { 
  value = random_password.ftp_pwd.result
  description = "Admin password."
  sensitive   = true
}

resource "azurerm_linux_virtual_machine" "main" {
  name                = join("", [var.scenarioPrefix, "VM"])
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vmSize
  admin_username      = var.username
  admin_password      = random_password.ftp_pwd.result
  computer_name = join("", [var.scenarioPrefix, "VM"])
  allow_extension_operations = true

  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  admin_ssh_key {
    username   = var.username
    public_key = tls_private_key.ftp_ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.imagePublisher
    offer     = var.imageOffer
    sku       = var.ubuntuOSVersion
    version   = "latest"
  }
}

locals {
  command = join("",["bash ./install.sh --account=", azurerm_storage_account.main.name, " --key=", azurerm_storage_account.main.primary_access_key , " --container=" , var.FtpFileContainerName, " --adminpassword=" , random_password.ftp_pwd.result])
  fileuri = "https://raw.githubusercontent.com/theonemule/azure-blog-storage-ftp-server/master/install.sh"
}

resource "azurerm_virtual_machine_extension" "main" {
  name                 = join("", [var.scenarioPrefix, "VMextensions"])
  virtual_machine_id   = azurerm_linux_virtual_machine.main.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "fileUris": ["https://raw.githubusercontent.com/theonemule/azure-blog-storage-ftp-server/master/install.sh"],
      "commandToExecute": "${local.command}"
    }
SETTINGS
}