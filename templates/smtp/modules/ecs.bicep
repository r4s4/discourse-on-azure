param name string
param tagsByResource object = {}
param dataLocation string
param domainName string

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

output acsName string = acsResource.name
output customDomainEmailAddress string = '${customEmailUsername}@${domainName}'
