param virtualNetworkName string
param location string = resourceGroup().location

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
  }

  resource subnetForPostgres 'subnets' = {
    name: 'postgresSubnet'
    properties: {
      addressPrefix: '10.0.1.0/24'
      delegations: [
        {
          name: 'dlg-Microsoft.DBforPostgreSQL-flexibleServers'
          properties: {
            serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
          }
        }
      ]
    }
  }


  resource subnetForContainerApps 'subnets' = {
    name: 'containerAppsSubnet'
    properties: {
      addressPrefix: '10.0.2.0/23'
      privateEndpointNetworkPolicies: 'Enabled'
      privateLinkServiceNetworkPolicies: 'Enabled'
      delegations: [
        {
          name: 'dlg-Microsoft.App-environments'
          properties: {
            serviceName: 'Microsoft.App/environments'
          }
        }
      ]
      serviceEndpoints: [
        {
          service: 'Microsoft.Storage'
        }
      ]
    }
    dependsOn: [
      subnetForPostgres
    ]
  }
}

output postgresSubnetName string = virtualNetwork::subnetForPostgres.name
output postgresSubnetId string = virtualNetwork::subnetForPostgres.id
output containerAppsSubnetName string = virtualNetwork::subnetForContainerApps.name
output containerAppsSubnetId string = virtualNetwork::subnetForContainerApps.id
