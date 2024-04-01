param storageAccountPrefix string
param location string = resourceGroup().location

param redisSubnetId string
param containersSubnetId string

var storageAccountName = substring('${storageAccountPrefix}${uniqueString(subscription().id, resourceGroup().id, storageAccountPrefix)}', 0, 24)

resource storageAccountResource 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_RAGRS'
  }
  properties: {
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: redisSubnetId
        }
        {
          id: containersSubnetId
        }
      ]
    }
    publicNetworkAccess: 'Enabled'
  }
}

output storageAccountName string = storageAccountResource.name
#disable-next-line outputs-should-not-contain-secrets
output storageAccountAccessKey string = storageAccountResource.listKeys().keys[0].value
