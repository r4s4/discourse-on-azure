param redisServerName string
param location string = resourceGroup().location

param containerAppEnvResourceName string 
param containerAppEnvResourceId string 

param storageAccountName string
@secure()
param storageAccountKey string 

resource redisFileShareResource 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = {
  name: '${storageAccountName}/default/redis-fs'
  properties: {
    accessTier: 'Cool'
    shareQuota: 1
  }
}

resource containerAppEnvSharedMount 'Microsoft.App/managedEnvironments/storages@2023-08-01-preview' = {
  name: '${containerAppEnvResourceName}/redis-files'
  properties: {
    azureFile: {
      accountName: storageAccountName
      accountKey: storageAccountKey
      shareName: split(redisFileShareResource.name, '/')[2]
      accessMode: 'ReadWrite'
    }
  }
}

resource redisAppResource 'Microsoft.App/containerapps@2023-05-02-preview' = {
  name: redisServerName
  location: location
  properties: {
    environmentId: containerAppEnvResourceId
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        transport: 'tcp'
        exposedPort: 6379
        targetPort: 6379
      }
    }
    template: {
      containers: [
        {
          name: redisServerName
          image: 'redis:7'
          resources: {
            cpu: 1
            memory: '2Gi'
          }
          volumeMounts: [
            {
              mountPath: '/data'
              volumeName: 'redis-volume'
            }
          ]
        }
      ]
      volumes: [
        {
          name: 'redis-volume'
          storageType: 'AzureFile'
          storageName: split(containerAppEnvSharedMount.name, '/')[1]
        }
      ]
    }
    workloadProfileName: 'Consumption'
  }
}

output redisHost string = redisAppResource.name
