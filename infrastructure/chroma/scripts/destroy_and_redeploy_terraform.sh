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