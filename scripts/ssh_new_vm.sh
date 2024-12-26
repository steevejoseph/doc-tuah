#!/bin/bash

# SSH into the new VM
# -o StrictHostKeyChecking=no: Automatically accept the new host key
# $(terraform output -raw public_ip_address): Get the IP address from terraform output
ssh -o StrictHostKeyChecking=no azureuser@$(terraform output -raw public_ip_address)



