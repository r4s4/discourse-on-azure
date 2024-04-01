param ecsName string
param domainName string

param ecsDataLocation string = 'Europe'

param appRegAppId string
param appRegPrinId string
param appRegTenantId string
@secure()
param appRegClientSecret string

module ecsModule 'modules/ecs.bicep' = {
  name: 'ECS_Deployment'
  params: {
    name: ecsName
    dataLocation: ecsDataLocation
    domainName: domainName
    appRegPrinId: appRegPrinId
  }
}

output smtpSenderEmailAddress string = ecsModule.outputs.customDomainEmailAddress
output smtpServer string = 'smtp.azurecomm.net'
output smtpPort string = '587'
output smtpEncryption string = 'TLS'
output smtpUsername string = '${ecsModule.outputs.acsName}.${appRegAppId}.${appRegTenantId}'
#disable-next-line outputs-should-not-contain-secrets
output smtpPassword string = appRegClientSecret
