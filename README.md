# Doc Tuah: A RAG App That Allows you to Chat with Docs

## Setup

First, infrastructure needs to be setup. In `infrastructure`, there are folders for chromaDB setup in Azure and Azure OpenAI Embeddings Setup.

<!-- TODO(stjoseph): Streamline the Terraform deployment to have one file set up everything  -->
     Issue URL: https://github.com/steevejoseph/doc-tuah/issues/2

Do the chromaDB part first with Terraform and then do the Azure setup part (working on streamlining this)

## Use

Some example commands

```python
# (From the root of the project, using python3)

# Fill db with local files (Monopoly and Ticket To Ride)
#  - only needs to be called once
python -m app.services.populate_database


# Chat with the DB
python -m app.services.query_data "How do I get 200 dollars"


# Optional Clear database (e.g. when using a model with different dimensionality)
python -m app.services.populate_database --reset
```
