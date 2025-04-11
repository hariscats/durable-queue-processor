# Durable Queue Processor Demo

A simple demo showing Azure Durable Functions processing messages from Service Bus queues using Python.

## Prerequisites

- Python 3.9+
- [Azure Functions Core Tools](https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local#install-the-azure-functions-core-tools)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)

## Quick Start

1. Clone and setup:
```bash
git clone <repository-url>
cd durable-queue-processor
python -m venv .venv
source .venv/bin/activate
pip install -r src/requirements.txt
```

2. Deploy infrastructure:
```bash
az login
az group create --name rg-queueproc-dev --location westeurope
az deployment group create --resource-group rg-queueproc-dev --template-file infra/main.bicep
```

3. Deploy function app:
```bash
cd src
func azure functionapp publish queueproc-func-dev --build remote
```

## Testing

1. Configure connection string for Service Bus:
```bash
cd test
echo "SERVICEBUS_CONNECTION_STRING=<your-service-bus-connection-string>" > .env
```

2. Run the test script:
```bash
python test_send_message.py
```

3. View function logs in Log Stream within App Insights to confirm.

You should see the following log entries:
- "Service Bus message received"
- "Started orchestration with ID"
- "Processing message"
- "Processed message"

## Project Structure

- `/src` - Function app source code
- `/infra` - Bicep infrastructure templates
- `/test` - Test scripts and configurations
