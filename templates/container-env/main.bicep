param containerEnvName string
param location string = resourceGroup().location

param containerAppSubnetId string 

resource containerAppLogWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${replace(containerEnvName, '-', '')}lw'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource containerAppEnvResource 'Microsoft.App/managedEnvironments@2023-08-01-preview' = {
  name: containerEnvName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: containerAppLogWorkspace.properties.customerId
        sharedKey: containerAppLogWorkspace.listKeys().primarySharedKey
      }
    }
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
    vnetConfiguration: {
      infrastructureSubnetId: containerAppSubnetId
      internal: false
    }
    zoneRedundant: false
  }
}

output containerAppEnvResourceName string = containerAppEnvResource.name
output containerAppEnvResourceId string = containerAppEnvResource.id
