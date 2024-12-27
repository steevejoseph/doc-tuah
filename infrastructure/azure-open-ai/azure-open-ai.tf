
# This Terraform file covers creating:

# 1. Azure OpenAI Service (azurerm_cognitive_account)
#     - Name: cognitive-openai
#     - Location: eastus
#     - SKU: S0

# 2. Model Deployments (azurerm_cognitive_deployment)
#     - Chat: gpt-35-turbo v0301
#     - Embeddings: text-embedding-ada-002 v2

# Variables
variable "subscription_id" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

provider "azurerm" {
 features {}
 subscription_id = var.subscription_id
}

# Resources

# Don't create the rg here, should already be created by Chroma terraform part
# TODO(steevejoseph): Ideally a root tf should create everything
# Issue URL: https://github.com/steevejoseph/doc-tuah/issues/1
# For now we must do the chroma terraform deployment then the azure-open-ai terraform deployment
# resource "azurerm_resource_group" "openai" {
#   name     = var.resource_group_name
#   location = var.location
# }

resource "azurerm_cognitive_account" "openai" {
  name                = "cognitive-openai"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "OpenAI"
  sku_name            = "S0"
}

resource "azurerm_cognitive_deployment" "chat" {
  name                 = "chat-deployment"
  cognitive_account_id = azurerm_cognitive_account.openai.id
  model {
    format  = "OpenAI"
    name    = "gpt-35-turbo"
    version = "0301"
  }
  sku {
    name     = "Standard"
    capacity = 1
  }
}

resource "azurerm_cognitive_deployment" "embedding" {
  name                 = "embedding-deployment"
  cognitive_account_id = azurerm_cognitive_account.openai.id
  model {
    format  = "OpenAI"
    name    = "text-embedding-ada-002"
    version = "2"
  }
  sku {
    name     = "Standard"
    capacity = 1
  }
}
