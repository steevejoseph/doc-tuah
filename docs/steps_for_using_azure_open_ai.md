# Steps for Using Azure OpenAI 

1. Create Azure OpenAI resource in Azure portal

2. Deploy two models:
   - Text generation model (gpt-35-turbo) for chat/queries
   - Text embedding model (text-embedding-ada-002) for generating embeddings

3. Get credentials:
   - API key
   - Endpoint URL
   - Both deployment names

4. Update embedding code:
```python
# get_embedding_funtion.py
from langchain_openai import AzureOpenAIEmbeddings 

def get_embedding_function():
    embeddings = AzureOpenAIEmbeddings(
        azure_endpoint="your-endpoint",
        api_key="your-key",
        api_version="2024-02-15-preview", 
        deployment_name="your-embedding-deployment-name"
    )
    return embeddings
```

5. Update chat model code:
```python
# query_model.py
model = AzureOpenAI(
    azure_endpoint="same-endpoint-as-embeddings",
    api_key="same-key-as-embeddings",
    api_version="2024-02-15-preview", 
    deployment_name="your-chat-deployment-name"  # Different from embedding deployment
)
```


## Steps 1 & 2: Creating Azure OpenAI Resource and Deploying Models

The simplest way to do this is via terraform:

```bash
# In infrastructure/azure-open-ai
terraform init
terraform plan -varfile="your-var-file-name" -out tfplan
terraform apply tfplan
```


### The Terraform file covers:
1. Creating Azure OpenAI Service (azurerm_cognitive_account)
   - Name: cognitive-openai
   - Location: eastus
   - SKU: S0

2. Model Deployments (azurerm_cognitive_deployment)
   - Chat: gpt-35-turbo v0301
   - Embeddings: text-embedding-ada-002 v2


### I don't see the models in Azure Portal
If `terraform init`, `terraform plan` and `terraform apply` succeed (i.e. no errors), the specified resources should have been created without issue.

You may not see the resources in Azure portal immediately, but as a sanity check, you can run the following terminal commands to check the deployement status:

```bash

# check if the deployments exist using Azure CLI:
az cognitiveservices account deployment list --name cognitive-openai --resource-group your-resource-group-name

# check the specific deployment status
az cognitiveservices account deployment show --deployment-name chat-deployment --resource-group your-resource-group-name --name cognitive-openai
```

These will return some json that you can parse visually for the status of those deployments

You can also check for the deployments in [Azure OpenAI Studio (https://oai.azure.com/
)](https://oai.azure.com/
)

The important thing is that the deployments are actually there and working, as confirmed by the CLI output. You should be able to use these deployments in your applications using the deployment names "chat-deployment" and "embedding-deployment".

## Step 3: Get credentials
