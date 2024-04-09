param location string = resourceGroup().location

param serverName string
param adminLoginUsername string
@secure()
#disable-next-line secure-parameter-default
param adminLoginPassword string = uniqueString(subscription().id, resourceGroup().id, 'postgresPassword')

param postgresSubnetId string

param databaseName string = 'discourse'
param tags object = {
  label: 'data'
}

resource privateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: '${serverName}.private.postgres.database.azure.com'
  tags: tags
  location: 'global'

  resource privateDNSLinks 'virtualNetworkLinks' = {
    name: uniqueString(subscription().id, resourceGroup().id, postgresSubnetId)
    location: 'global'

    properties: {
      virtualNetwork: {
        id: resourceId('Microsoft.Network/virtualNetworks', split(postgresSubnetId, '/')[8])
      }
      registrationEnabled: true
    }
  }
}

resource postgresServerResource 'Microsoft.DBforPostgreSQL/flexibleServers@2023-06-01-preview' = {
  name: serverName
  tags: tags
  location: location
  properties: {
    createMode: 'Default'
    version: '16'
    administratorLogin: adminLoginUsername
    administratorLoginPassword: adminLoginPassword
    storage: {
      storageSizeGB: 32
      autoGrow: 'Enabled'
      tier: 'P4'
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    network: {
      delegatedSubnetResourceId: postgresSubnetId
      privateDnsZoneArmResourceId: privateDNSZone.id
    }
  }
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }

  resource postgresfirewallRules 'firewallRules' = {
    name: 'AllowAllAzureServicesAndResourcesWithinAzureIps'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '0.0.0.0'
    }
  }

  resource postgresConfigurations 'configurations' = {
    name: 'azure.extensions'
    properties: {
      value: 'HSTORE,PG_TRGM,UNACCENT'
      source: 'user-override'
    }
    dependsOn: [postgresfirewallRules]
  }

  resource postgresDiscourseDatabase 'databases' = {
    name: databaseName
    properties: {
      charset: 'UTF8'
      collation: 'en_US.utf8'
    }
    dependsOn: [postgresConfigurations]
  }
}

output username string = adminLoginUsername
#disable-next-line outputs-should-not-contain-secrets
output userPassword string = adminLoginPassword
output dbName string = databaseName
output dbHostname string = postgresServerResource.properties.fullyQualifiedDomainName
