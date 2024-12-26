#!/bin/bash

# This script performs a complete redeployment of the Chroma infrastructure
# It will destroy existing resources, create new ones, and SSH into the new VM

# Destroy existing infrastructure
# -auto-approve: Skip interactive approval
# -var-file: Use variables from chroma.tfvars
terraform destroy -auto-approve -var-file chroma.tfvars 

# Create new infrastructure
# -auto-approve: Skip interactive approval
# -var-file: Use variables from chroma.tfvars
terraform apply -auto-approve -var-file chroma.tfvars 

# SSH into the new VM
# -o StrictHostKeyChecking=no: Automatically accept the new host key
# $(terraform output -raw public_ip_address): Get the IP address from terraform output
# ssh -o StrictHostKeyChecking=no azureuser@$(terraform output -raw public_ip_address)



