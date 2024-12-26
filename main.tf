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

provider "azurerm" {
  # @steeve: remove this before checking in
  subscription_id = "01def7cf-f6e4-449d-88de-1e20f2291bc8"
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
    disk_size_gb = 30
  }

  source_image_reference {
    publisher = "Debian"
    offer     = "debian-11"
    sku       = "11"
    version   = "latest"
  }

  custom_data = base64encode(<<EOT
    #!/bin/bash
    set -e  # Exit on error

    # Function for retrying commands
    retry_command() {
        local retries=5
        local wait=10
        local command="$@"
        local n=1
        until [ $n -gt $retries ]
        do
            echo "Attempt $${n}/$${retries}: $${command}"
            $${command} && break || {
                if [ $${n} -eq $${retries} ]; then
                    echo "Command '$${command}' failed after $${n} attempts"
                    return 1
                fi
                echo "Command failed. Waiting $${wait} seconds..."
                sleep $${wait}
                ((n++))
            }
        done
    }

    # Function to detect OS and set package manager
    setup_package_manager() {
        if [ -f /etc/debian_version ]; then
            PKG_MANAGER="apt-get"
            PKG_UPDATE="$PKG_MANAGER update"
            PKG_INSTALL="$PKG_MANAGER install -y"
            OS_FAMILY="debian"
        elif [ -f /etc/redhat-release ]; then
            PKG_MANAGER="dnf"
            PKG_UPDATE="$PKG_MANAGER check-update"
            PKG_INSTALL="$PKG_MANAGER install -y"
            OS_FAMILY="redhat"
        else
            echo "Unsupported operating system"
            exit 1
        fi
    }

    # Initialize system
    echo "Initializing system..."
    setup_package_manager

    # Update package list
    echo "Updating package list..."
    retry_command "$PKG_UPDATE"

    # Install prerequisites
    echo "Installing prerequisites..."
    retry_command "$PKG_INSTALL \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release"

    # Install Docker using official script
    echo "Installing Docker..."
    retry_command "curl -fsSL https://get.docker.com -o get-docker.sh"
    retry_command "sh get-docker.sh"
    rm get-docker.sh

    # Start and enable Docker
    echo "Starting Docker service..."
    systemctl start docker
    systemctl enable docker

    # Create chroma user and group
    echo "Setting up Chroma user..."
    useradd -r -s /bin/false chroma || true
    usermod -aG docker chroma

    # Set up Chroma
    echo "Setting up Chroma..."
    mkdir -p /home/chroma
    cd /home/chroma

    # Download and verify docker-compose file
    echo "Downloading Chroma docker-compose file..."
    retry_command "curl -o docker-compose.yml https://s3.amazonaws.com/public.trychroma.com/cloudformation/assets/docker-compose.yml"

    # Update Chroma version if specified
    if [ ! -z "${var.chroma_version}" ]; then
        sed -i "s/latest/${var.chroma_version}/g" docker-compose.yml
    fi

    # Create .env file with proper quoting
    echo "Creating Chroma environment file..."
    cat > .env <<EOF
    CHROMA_SERVER_AUTHN_CREDENTIALS="${var.chroma_server_auth_credentials}"
    CHROMA_SERVER_AUTHN_PROVIDER="${var.chroma_server_auth_provider}"
    CHROMA_AUTH_TOKEN_TRANSPORT_HEADER="${var.chroma_auth_token_transport_header}"
    CHROMA_OTEL_COLLECTION_ENDPOINT="${var.chroma_otel_collection_endpoint}"
    CHROMA_OTEL_SERVICE_NAME="${var.chroma_otel_service_name}"
    CHROMA_OTEL_COLLECTION_HEADERS='${var.chroma_otel_collection_headers}'
    CHROMA_OTEL_GRANULARITY="${var.chroma_otel_granularity}"
    EOF

    # Set proper permissions
    echo "Setting proper permissions..."
    chown -R chroma:chroma /home/chroma
    chmod 600 /home/chroma/.env

    # Start Chroma
    echo "Starting Chroma..."
    cd /home/chroma
    docker compose up -d

    # Wait for Chroma to be ready with improved error handling
    echo "Waiting for Chroma to be ready..."
    for i in {1..30}; do
        if curl -s http://localhost:8000/api/v1/heartbeat > /dev/null; then
            echo "Chroma is ready!"
            break
        fi
        if [ $i -eq 30 ]; then
            echo "Timeout waiting for Chroma to start"
            docker compose logs
            exit 1
        fi
        echo "Waiting for Chroma to start... (attempt $${i}/30)"
        sleep 10
    done

    # Final status check
    echo "Checking final status..."
    docker ps
    docker compose logs

    echo "Initialization complete!"
  EOT
  )
}

# Output
output "public_ip_address" {
  description = "Public IP address of the Chroma server"
  value       = azurerm_public_ip.public_ip.ip_address
}
