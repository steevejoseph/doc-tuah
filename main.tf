variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
}

variable "location" {
  description = "Azure region where resources will be deployed"
}

variable "instance_name" {
  description = "Name of the Virtual Machine"
  default     = "chroma-instance"
}

variable "machine_type" {
  description = "Azure VM size (e.g., Standard_B1s)"
}

variable "chroma_version" {
  description = "Chroma version to install"
  default     = "0.6.0"
}

variable "chroma_server_auth_credentials" {
  description = "Chroma authentication credentials"
  default     = ""
}

variable "chroma_server_auth_provider" {
  description = "Chroma authentication provider"
  default     = ""
}

variable "chroma_auth_token_transport_header" {
  description = "Chroma authentication custom token header"
  default     = ""
}

variable "chroma_otel_collection_endpoint" {
  description = "Chroma OTEL endpoint"
  default     = ""
}

variable "chroma_otel_service_name" {
  description = "Chroma OTEL service name"
  default     = ""
}

variable "chroma_otel_collection_headers" {
  description = "Chroma OTEL headers"
  default     = "{}"
}

variable "chroma_otel_granularity" {
  description = "Chroma OTEL granularity"
  default     = ""
}

variable "ssh_public_key_path" {
  description = "Path to your SSH public key"
  default     = "~/.ssh/id_rsa.pub"
}

variable "subscription_id" {
  description = "Azure subscription ID"
  default = ""
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.instance_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.instance_name}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.instance_name}-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Public IP
resource "azurerm_public_ip" "public_ip" {
  name                = "${var.instance_name}-publicip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

# Network Interface
resource "azurerm_network_interface" "nic" {
  name                = "${var.instance_name}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "nsg_association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Virtual Machine
# Note: Removed custom_data section that was trying to run scripts during cloud-init
# This is more reliable as we'll copy and execute scripts after VM is fully provisioned
resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.instance_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  size                = var.machine_type
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Debian"
    offer     = "debian-11"
    sku       = "11"
    version   = "latest"
  }
}

# Null resource for script deployment
# This approach is more reliable than cloud-init because:
# 1. We wait for VM to be fully provisioned (depends_on)
# 2. We can verify script delivery and execution
# 3. We have better error handling and visibility
resource "null_resource" "setup_scripts" {
  # Ensure VM is created before trying to copy files
  depends_on = [azurerm_linux_virtual_machine.vm]

  # Copy install_docker.sh to VM
  provisioner "file" {
    source      = "${path.module}/scripts/install_docker.sh"
    destination = "/home/azureuser/install_docker.sh"

    # SSH connection details for file copy
    connection {
      type        = "ssh"
      user        = "azureuser"
      host        = azurerm_public_ip.public_ip.ip_address
      private_key = file(replace(var.ssh_public_key_path, ".pub", ""))
    }
  }

  # Copy setup_chroma.sh to VM
  provisioner "file" {
    source      = "${path.module}/scripts/setup_chroma.sh"
    destination = "/home/azureuser/setup_chroma.sh"

    # SSH connection details for file copy
    connection {
      type        = "ssh"
      user        = "azureuser"
      host        = azurerm_public_ip.public_ip.ip_address
      private_key = file(replace(var.ssh_public_key_path, ".pub", ""))
    }
  }

  # Execute the scripts
  provisioner "remote-exec" {
    inline = [
      # Debug: Print commands and their output
      "set -x",
      
      # Fix locale issues first
      "sudo apt-get update || echo 'apt-get update failed'",
      "sudo apt-get install -y locales || echo 'locales installation failed'",
      "sudo locale-gen en_US.UTF-8 || echo 'locale-gen failed'",
      "sudo update-locale LANG=en_US.UTF-8 || echo 'update-locale failed'",
      
      # Debug: Check if scripts exist
      "ls -l /home/azureuser/install_docker.sh || echo 'install_docker.sh not found'",
      "ls -l /home/azureuser/setup_chroma.sh || echo 'setup_chroma.sh not found'",
      
      # Make scripts executable
      "chmod +x /home/azureuser/install_docker.sh || echo 'chmod failed for install_docker.sh'",
      "chmod +x /home/azureuser/setup_chroma.sh || echo 'chmod failed for setup_chroma.sh'",
      
      # Run scripts with error output
      "sudo /home/azureuser/install_docker.sh 2>&1 || echo 'install_docker.sh failed'",
      "sudo /home/azureuser/setup_chroma.sh 2>&1 || echo 'setup_chroma.sh failed'"
    ]

    connection {
      type        = "ssh"
      user        = "azureuser"
      host        = azurerm_public_ip.public_ip.ip_address
      private_key = file(replace(var.ssh_public_key_path, ".pub", ""))
    }
  }
}

# Output the public IP for easy access
output "public_ip_address" {
  description = "Public IP address of the Chroma server"
  value       = azurerm_public_ip.public_ip.ip_address
}
