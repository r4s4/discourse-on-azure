param name string
param tagsByResource object = {}
param dataLocation string
param domainName string

param appRegPrinId string

// Email Username and DisplayName parameters
param customEmailUsername string = 'donotreply'
param customEmailDisplayName string = 'DoNotReply'

resource ecsResource 'Microsoft.Communication/emailServices@2021-10-01-preview' = {
  name: name
  location: 'global'
  tags: (contains(tagsByResource, 'Microsoft.Communication/EmailServices') ? tagsByResource['Microsoft.Communication/EmailServices'] : json('{}'))
  properties: {
    dataLocation: dataLocation
  }

  resource ecsResourceCustomDomain 'domains@2023-06-01-preview' = {
    name: domainName
    location: 'global'
    properties: {
      domainManagement: 'CustomerManaged'
      userEngagementTracking: 'Disabled'
    }

    resource ecsResourceCustomDomainEmailAddress 'senderusernames@2023-06-01-preview' = {
      name: customEmailUsername
      properties: {
        username: customEmailUsername
        displayName: customEmailDisplayName
      }
    }
  }
}

resource acsResource 'Microsoft.Communication/CommunicationServices@2023-06-01-preview' = {
  name: '${name}-acs'
  location: 'global'
  properties: {
    dataLocation: dataLocation
    linkedDomains: [ecsResource::ecsResourceCustomDomain.id]
  }
}

@description('This is the built-in Contributor role. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#contributor')
resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, appRegPrinId, contributorRoleDefinition.id)
  scope: acsResource
  properties: {
    roleDefinitionId: contributorRoleDefinition.id
    principalId: appRegPrinId
    principalType: 'ServicePrincipal'
  }
}

output acsName string = acsResource.name
output customDomainEmailAddress string = '${customEmailUsername}@${domainName}'
