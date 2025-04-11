@description('The location for all resources')
param location string = resourceGroup().location

@description('Environment name (dev, test, prod)')
param environmentName string = 'dev'

@description('Base name for all resources')
param appName string = 'queueproc'

// Naming variables
var functionAppName = '${appName}-func-${environmentName}'
var serviceBusName = '${appName}-sb-${environmentName}'
var storageAccountName = replace(functionAppName, '-', '')
var hostingPlanName = '${functionAppName}-plan'

// Service Bus Namespace
resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
  name: serviceBusName
  location: location
  sku: {
    name: 'Standard'
  }
}

// Service Bus Queue
resource serviceBusQueue 'Microsoft.ServiceBus/namespaces/queues@2021-11-01' = {
  parent: serviceBusNamespace
  name: 'messages'
  properties: {
    maxDeliveryCount: 10
    lockDuration: 'PT5M'
  }
}

// Service Bus Authorization Rule
resource serviceBusAuthRule 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2021-11-01' existing = {
  parent: serviceBusNamespace
  name: 'RootManageSharedAccessKey'
}

// Storage Account for Function App
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

// App Service Plan
resource hostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: hostingPlanName
  location: location
  kind: 'linux'
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: true // Required for Linux
  }
}

// Function App
resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  properties: {
    serverFarmId: hostingPlan.id
    reserved: true // Required for Linux
    siteConfig: {
      linuxFxVersion: 'Python|3.9'
      appSettings: [
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
        }
        {
          name: 'ServiceBusConnection'
          value: listKeys(serviceBusAuthRule.id, serviceBusAuthRule.apiVersion).primaryConnectionString
        }
        {
          name: 'WEBSITE_MOUNT_ENABLED'
          value: '1'
        }
        {
          name: 'PYTHON_ENABLE_WORKER_EXTENSIONS'
          value: '1'
        }
        {
          name: 'ENABLE_ORYX_BUILD'
          value: 'true'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
      ]
    }
  }
}

// Outputs
output functionAppName string = functionApp.name
output serviceBusNamespace string = serviceBusNamespace.name
output serviceBusConnectionString string = listKeys(serviceBusAuthRule.id, serviceBusAuthRule.apiVersion).primaryConnectionString
