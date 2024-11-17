@description('The location of the resources')
param location string = 'polandcentral'

@description('The name of the project')
param projectName string = 'cdw-automation'

@description('Short code for project name')
@minLength(1)
@maxLength(5)
param projectShortName string = 'cdw'

@description('Environment')
@allowed([
  'prd'
  'dev'
])
param env string = 'dev'

@secure()
param spotifyClientId string

@secure()
param spotifyClientSecret string

@secure()
param spotifyRadarPlaylistId string

@secure()
param spotifyBachata2024PlaylistId string

var storageAccountName = '${replace(projectShortName, '-', '')}${substring(uniqueString(resourceGroup().id), 0, 3)}${env}01sa'
var appServicePlanName = '${projectName}-${env}-01-asp'
var functionAppName = '${projectName}-${env}-01-fnapp'
var managedIdentityName = '${projectName}-${env}-01-id'
var lawName = '${projectName}-${env}-01-log'
var applicationInsightsName = '${projectName}-${env}-01-appi'
var keyVaultName = '${projectName}-${env}-01-appi'

var spotifyClientIdSecretName = ''
var spotifyClientSecretSecretName = ''
var spotifyRadarPlaylistIdSecretName = ''
var spotifyBachata2024PlaylistIdSecretName = ''

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    defaultToOAuthAuthentication: true
    minimumTlsVersion: 'TLS1_2'
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
}

resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'RunOnStartup'
          value: 'false'
        }
        {
          name: 'AZURE_CLIENT_ID'
          value: managedIdentity.properties.clientId
        }
        {
          name: spotifyClientIdSecretName
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=${spotifyClientIdSecret.name})'
        }
        {
          name: spotifyClientSecretSecretName
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=${spotifyClientSecretSecret.name})'
        }
        {
          name: spotifyRadarPlaylistIdSecretName
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=${spotifyRadarPlaylistIdSecret.name})'
        }
        {
          name: spotifyBachata2024PlaylistIdSecretName
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=${spotifyBachata2024PlaylistIdSecret.name})'
        }
      ]
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      use32BitWorkerProcess: false
      netFrameworkVersion: 'v8.0'
    }
    httpsOnly: true
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: managedIdentityName
  location: location
}

resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: lawName
  location: location
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    WorkspaceResourceId: law.id
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    enableRbacAuthorization: true
    enabledForDeployment: true
  }
}

resource spotifyClientIdSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: spotifyClientIdSecretName
  properties: {
    value: spotifyClientId
  }
}

resource spotifyClientSecretSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: spotifyClientSecretSecretName
  properties: {
    value: spotifyClientSecret
  }
}

resource spotifyRadarPlaylistIdSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: spotifyRadarPlaylistIdSecretName
  properties: {
    value: spotifyRadarPlaylistId
  }
}

resource spotifyBachata2024PlaylistIdSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: spotifyBachata2024PlaylistIdSecretName
  properties: {
    value: spotifyBachata2024PlaylistId
  }
}
