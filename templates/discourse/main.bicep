param appName string
param location string = resourceGroup().location

param containerAppEnvResourceName string
param containerAppEnvResourceId string

param storageAccountName string
@secure()
param storageAccountKey string

param discourseDomainName string
param discourseDeveloperEmail string
param discourseSMTPAddress string
param discourseSMTPPort string
param discourseSMTPUser string
param discourseSMTPPass string
param discourseSMTPEmailDomain string
param discourseSMTPEmail string
param discourseDbHost string
param discourseDbName string
param discourseDbUser string
param discourseDbPass string
param discourseRedisHost string

resource discourseSharedFileShareResource 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = {
  name: '${storageAccountName}/default/discourse-shared'
  properties: {
    accessTier: 'Cool'
  }
}

resource discourseLogsFileShareResource 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = {
  name: '${storageAccountName}/default/discourse-log'
  properties: {
    accessTier: 'Cool'
  }
}

resource containerAppEnvSharedMount 'Microsoft.App/managedEnvironments/storages@2023-08-01-preview' = {
  name: '${containerAppEnvResourceName}/sharedfiles'
  properties: {
    azureFile: {
      accountName: storageAccountName
      accountKey: storageAccountKey
      shareName: split(discourseSharedFileShareResource.name, '/')[2]
      accessMode: 'ReadWrite'
    }
  }
}

resource containerAppEnvLogsMount 'Microsoft.App/managedEnvironments/storages@2023-08-01-preview' = {
  name: '${containerAppEnvResourceName}/logsfiles'
  properties: {
    azureFile: {
      accountName: storageAccountName
      accountKey: storageAccountKey
      shareName: split(discourseLogsFileShareResource.name, '/')[2]
      accessMode: 'ReadWrite'
    }
  }
}

resource containerAppResource 'Microsoft.App/containerapps@2023-05-02-preview' = {
  name: appName
  location: location
  properties: {
    environmentId: containerAppEnvResourceId
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        transport: 'Auto'
        allowInsecure: false
        targetPort: 80
        stickySessions: {
          affinity: 'sticky'
        }
      }
    }
    template: {
      containers: [ {
          name: appName
          image: 'ghcr.io/pschichtel/discourse:stable-web-only'
          command: [ '/sbin/boot' ]
          resources: {
            cpu: 1
            memory: '2Gi'
          }
          env: [
            {
              name: 'UNICORN_WORKERS'
              value: '3'
            }
            {
              name: 'DISCOURSE_HOSTNAME'
              value: discourseDomainName
            }
            {
              name: 'DISCOURSE_DEVELOPER_EMAILS'
              value: discourseDeveloperEmail
            }
            {
              name: 'DISCOURSE_SMTP_ADDRESS'
              value: discourseSMTPAddress
            }
            {
              name: 'DISCOURSE_SMTP_PORT'
              value: discourseSMTPPort
            }
            {
              name: 'DISCOURSE_SMTP_USER_NAME'
              value: discourseSMTPUser
            }
            {
              name: 'DISCOURSE_SMTP_PASSWORD'
              value: discourseSMTPPass
            }
            {
              name: 'DISCOURSE_SMTP_DOMAIN'
              value: discourseSMTPEmailDomain
            }
            {
              name: 'DISCOURSE_SMTP_AUTHENTICATION'
              value: 'login'
            }
            {
              name: 'DISCOURSE_NOTIFICATION_EMAIL'
              value: discourseSMTPEmail
            }
            {
              name: 'DISCOURSE_DB_NAME'
              value: discourseDbName
            }
            {
              name: 'DISCOURSE_DB_USERNAME'
              value: discourseDbUser
            }
            {
              name: 'DISCOURSE_DB_PASSWORD'
              value: discourseDbPass
            }
            {
              name: 'DISCOURSE_DB_HOST'
              value: discourseDbHost
            }
            {
              name: 'DISCOURSE_REDIS_HOST'
              value: discourseRedisHost
            }
            {
              name: 'DISCOURSE_FORCE_HTTPS'
              value: 'true'
            }
            {
              name: 'UNICORN_SIDEKIQS'
              value: '1'
            }
          ]
          volumeMounts: [
            {
              mountPath: '/shared'
              volumeName: 'shared-volume'
            }
            {
              mountPath: '/var/log'
              volumeName: 'logs-volume'
            }
          ]
        }
      ]
      volumes: [
        {
          name: 'shared-volume'
          storageType: 'AzureFile'
          storageName: split(containerAppEnvSharedMount.name, '/')[1]
        }
        {
          name: 'logs-volume'
          storageType: 'AzureFile'
          storageName: split(containerAppEnvLogsMount.name, '/')[1]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
        rules: [
          {
            name: '1000-conc-http-rule'
            http: {
              metadata: {
                concurrentRequests: '1000'
              }
            }
          }
        ]
      }
    }
    workloadProfileName: 'Consumption'
  }
}
