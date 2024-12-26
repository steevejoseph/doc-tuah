#!/bin/bash

# Install prerequisites including gpg
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg2 gpg

# Create keyrings directory
sudo install -m 0755 -d /etc/apt/keyrings

# Import the Docker GPG key directly
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

# Add Docker repository without gpg file approach
echo \
  "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update and install Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Create Chroma directory
sudo mkdir -p /home/chroma
sudo chown azureuser:azureuser /home/chroma

# Add current user to docker group
sudo usermod -aG docker azureuser
