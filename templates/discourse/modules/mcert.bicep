param location string = resourceGroup().location

param managedEnvironmentName string
param domainName string

resource managedEnvironmentManagedCertificate 'Microsoft.App/managedEnvironments/managedCertificates@2023-11-02-preview' = {
  name: '${managedEnvironmentName}/${domainName}-certificate'
  location: location
  properties: {
    subjectName: domainName
    domainControlValidation: 'CNAME'
  }
}

output certSubjectName string = managedEnvironmentManagedCertificate.properties.subjectName
output certId string = managedEnvironmentManagedCertificate.id
