param param_env string = 'dev'
param location string = resourceGroup().location
param param_Usage string = '01'
param param001 string = '001'
param param002 string = '002'
@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string

var prefix = json(loadTextContent('NamingPrefix.json'))
var pub_ip_props = json(loadTextContent('ResourcePropertyMapping.json'))['publicip']['${param_env}']

var vnet = '${prefix.virtualNetwork}-${prefix.companyShortName}-${param_Usage}-${param_env}'
var jumpVM = '${prefix.jumpVm}-${prefix.companyShortName}-${param_Usage}-${param_env}'
var jumpVM_nis = '${prefix.networkInterface}-${prefix.jumpVm}-${param_Usage}'
var public_ip = '${prefix.publicIP}-${prefix.companyShortName}-${param_Usage}'
var as_db_tier = '${prefix.availablitySets}-${prefix.companyShortName}-${prefix.databaseTier}-${param_Usage}'
var as_app_tier = '${prefix.availablitySets}-${prefix.companyShortName}-${prefix.applicationTier}-${param_Usage}'
var as_web_tier = '${prefix.availablitySets}-${prefix.companyShortName}-${prefix.webTier}-${param_Usage}'
var pub_ip_jump_vm = '${prefix.publicIP}-${prefix.jumpVm}-${param_env}'
var vm_db_1 = '${prefix.virtualMachine}-${prefix.companyShortName}-${prefix.databaseTier}-${param001}-${param_env}'
var vm_db_2 = '${prefix.virtualMachine}-${prefix.companyShortName}-${prefix.databaseTier}-${param002}-${param_env}'
var vm_app_1 = '${prefix.virtualMachine}-${prefix.companyShortName}-${prefix.applicationTier}-${param001}-${param_env}'
var vm_app_2 = '${prefix.virtualMachine}-${prefix.companyShortName}-${prefix.applicationTier}-${param002}-${param_env}'
var vm_web_1 = '${prefix.virtualMachine}-${prefix.companyShortName}-${prefix.webTier}-${param001}-${param_env}'
var vm_web_2 = '${prefix.virtualMachine}-${prefix.companyShortName}-${prefix.webTier}-${param002}-${param_env}'
var nsg_db_tier = '${prefix.networkSecurityGroup}-${prefix.companyShortName}-${prefix.databaseTier}-${param_Usage}'
var nsg_app_tier = '${prefix.networkSecurityGroup}-${prefix.companyShortName}-${prefix.applicationTier}-${param_Usage}'
var nsg_web_tier = '${prefix.networkSecurityGroup}-${prefix.companyShortName}-${prefix.webTier}-${param_Usage}'
var nsg_jump_vm = '${prefix.networkSecurityGroup}-${prefix.companyShortName}-${prefix.jumpVm}-${param_Usage}'
var lb_public = '${prefix.loadBalancerPublic}-${prefix.companyShortName}-${param_Usage}'
var lb_internal = '${prefix.loadBalancerInternal}-${prefix.companyShortName}-${param_Usage}'
var nis_db_tier_001 = '${prefix.networkInterface}-${prefix.companyShortName}-${prefix.databaseTier}-${param001}'
var nis_db_tier_002 = '${prefix.networkInterface}-${prefix.companyShortName}-${prefix.databaseTier}-${param002}'
var nis_app_tier_001 = '${prefix.networkInterface}-${prefix.companyShortName}-${prefix.applicationTier}-${param001}'
var nis_app_tier_002 = '${prefix.networkInterface}-${prefix.companyShortName}-${prefix.applicationTier}-${param002}'
var nis_web_tier_001 = '${prefix.networkInterface}-${prefix.companyShortName}-${prefix.webTier}-${param001}'
var nis_web_tier_002 = '${prefix.networkInterface}-${prefix.companyShortName}-${prefix.webTier}-${param002}'

//Creating network security group
resource nsg_app 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: nsg_app_tier
  location: location
  properties: {
    securityRules: []
  }
}

resource nsg_db 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: nsg_db_tier
  location: location
  properties: {
    securityRules: []
  }
}

resource nsg_web 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: nsg_web_tier
  location: location
  properties: {
    securityRules: []
  }
}

resource nsg_jump 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: nsg_jump_vm
  location: location
  properties: {
    securityRules: [
      {
        name: 'Port_8080'
        properties:{
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '49.37.167.48'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}

//creating public ip
resource pubip_jumpvm 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: pub_ip_jump_vm
  location: location
  sku: {
    name: pub_ip_props.sku.name
    tier: pub_ip_props.sku.tier
  }
  properties: {
    ipAddress: '40.121.64.90'
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    ipTags: []
  }
}

resource pub_ip 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: public_ip
  location: location
  sku: {
    name: pub_ip_props.sku.name
    tier: pub_ip_props.sku.tier
  }
  properties: {
    ipAddress: '40.121.133.254'
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    ipTags: []
  }
}

//creating virtual network - vn
resource vn 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnet
  location: location
  dependsOn: [
    nsg_app, nsg_db, nsg_web, nsg_jump
  ]
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'app-tier-subnet'
        properties: {
          addressPrefix: '10.0.7.0/24'
          networkSecurityGroup: {
            id: nsg_app.id
          }
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'db-tier-subnet'
        properties: {
          addressPrefix: '10.0.13.0/24'
          networkSecurityGroup: {
            id: nsg_db.id
          }
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'web-tier-subnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: nsg_web.id
          }
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'jump-subnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsg_web.id
          }
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

//Creating load balancer backend pool - app-tier-backend
resource lb_app_backend 'Microsoft.Network/loadBalancers/backendAddressPools@2022-07-01' = {
  name: concat(lb_internal,'/apptierbackend')
  dependsOn:[
    lb
  ]
  properties: {
    loadBalancerBackendAddresses: [
      {
        name: 'contos-app-tier-vm-001-ipconfig'
        properties: {}
      }
      {
        name: 'contos-app-tier-vm-002-ipconfig'
        properties: {}
      }
    ]
  }
}

//Creating load balancer backend pool - web-tier-backend
resource lb_web_backend 'Microsoft.Network/loadBalancers/backendAddressPools@2022-07-01' = {
  name: concat(lb_public,'/webtierbackend')
  dependsOn:[
    lb
  ]
  properties: {
    loadBalancerBackendAddresses: [
      {
        name: 'contos-web-tier-vm-001-ipconfig'
        properties: {}
      }
      {
        name: 'contos-web-tier-vm-002-ipconfig'
        properties: {}
      }
    ]
  }
}

//Creating load balancer - lb internal
resource lb_inter 'Microsoft.Network/loadBalancers@2021-08-01' = {
  name: lb_internal
  location: location
  dependsOn:[
    vn
  ]
  sku:{
    name:'Standard'
    tier: 'Regional'
  }
  properties:{
    frontendIPConfigurations:[
      {
        name: 'fronted-ip-internallb'
        properties:{
          privateIPAddress: '10.0.7.6'
          privateIPAllocationMethod: 'Static'
          subnet:{
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet, 'app-tier-subnet')
          }
          privateIPAddressVersion: 'IPv4'
        }
        zones:[
          '1','2','3'
        ]
      }
    ]
    backendAddressPools:[
      {
        name: 'apptierbackend'
        properties:{
          loadBalancerBackendAddresses: [
            {
              name: 'contos-app-tier-vm-001-ipconfig'
              properties: {}
            }
            {
              name: 'contos-app-tier-vm-002-ipconfig'
              properties: {}
            }
          ]
        }
      }
    ]
  }
}

//Creating load balancer - lb public
resource lb 'Microsoft.Network/loadBalancers@2021-08-01' = {
  name: lb_public
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'frontend-ip-externallb'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddress', public_ip)
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'webtierbackend'
        properties: {
          loadBalancerBackendAddresses: [
            {
              name: 'contos-web-tier-vm-001-ipconfig'
              properties: {}
            }
            {
              name: 'contos-web-tier-vm-002-ipconfig'
              properties: {}
            }
          ]
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'rule1'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lb_public, 'frontend-ip-externallb')
          }
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
          protocol: 'Tcp'
          enableTcpReset: false
          loadDistribution: 'Default'
          disableOutboundSnat: true
          backendAddressPool:{
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lb_public, 'webtierbackend')
            
          }
          probe: {
            id: concat(resourceId('Microsoft.Network/loadBalancer', lb_public, '/probes/probe1'))
          }
        }
      }
      {
        name: 'rule2'
        properties: {
          frontendIPConfiguration: {
            id: concat(resourceId('Microsoft.Network/loadBalancer', lb_public, '/frontendIPConfigurations/frontend-ip-externallb'))
          }
          frontendPort: 443
          backendPort: 443
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
          protocol: 'Tcp'
          enableTcpReset: false
          loadDistribution: 'Default'
          disableOutboundSnat: true
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lb_public, 'webtierbackend')
          }
          probe: {
            id: concat(resourceId('Microsoft.Network/loadBalancer', lb_public, '/probes/probe2'))
          }
        }
      }
    ]
    probes: [
      {
        name: 'probe1'
        properties: {
          protocol: 'Http'
          port: 80
          requestPath: '/'
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
      {
        name: 'probe2'
        properties:{
          protocol: 'Https'
          port: 443
          requestPath: '/'
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
    inboundNatRules: []
    inboundNatPools: []
    outboundRules: []
  }
}

//creating network interface db tier - nis-db-tier-001
resource nisdb001 'Microsoft.Network/networkInterfaces@2022-07-01' = {
  name: nis_db_tier_001
  location: location
  dependsOn: [
    vn, lb
  ]
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfiguration001'
        properties: {
          privateIPAddress: '10.0.13.4'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet, 'db-tier-subnet')
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }  
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: true
    enableIPForwarding: false
  }
}

//creating network interface db tier - nis-db-tier-002
resource nisdb002 'Microsoft.Network/networkInterfaces@2022-07-01' = {
  name: nis_db_tier_002
  location: location
  dependsOn: [
    vn, lb
  ]
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfiguration001'
        properties: {
          privateIPAddress: '10.0.13.5'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet, 'db-tier-subnet')
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }  
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: true
    enableIPForwarding: false
  }
}

//creating network interface - nis-app-tier-001
resource nisapp001 'Microsoft.Network/networkInterfaces@2022-07-01' = {
  name: nis_app_tier_001
  location: location
  dependsOn: [
    vn, lb
  ]
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfiguration001'
        properties: {
          privateIPAddress: '10.0.7.4'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet, 'app-tier-subnet')
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lb_internal, 'apptierbackend')
            }
          ]
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: true
    enableIPForwarding: false
  }
}

//creating network interface - nis-app-tier-002
resource nisapp002 'Microsoft.Network/networkInterfaces@2022-07-01' = {
  name: nis_app_tier_002
  location: location
  dependsOn: [
    vn, lb
  ]
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfiguration001'
        properties: {
          privateIPAddress: '10.0.7.5'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet, 'app-tier-subnet')
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lb_internal, 'apptierbackend')
            }
          ]
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: true
    enableIPForwarding: false
  }
}

//creating network interface - nisjumpvm
resource nisjumpvm 'Microsoft.Network/networkInterfaces@2022-07-01' = {
  name: jumpVM_nis
  location: location
  dependsOn: [
    vn, lb
  ]
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfiguration001'
        properties: {
          privateIPAddress: '10.0.0.4'
          privateIPAllocationMethod: 'Static'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddressess', pub_ip_jump_vm)
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet, 'jump-subnet')
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: true
    enableIPForwarding: false
  }
}

//creating network interface for web tier - nisweb001
resource nisweb001 'Microsoft.Network/networkInterfaces@2022-07-01' = {
  name: nis_web_tier_001
  location: location
  dependsOn: [
    vn, lb
  ]
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfiguration001'
        properties: {
          privateIPAddress: '10.0.1.4'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet, 'web-tier-subnet')
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lb_internal, 'webtierbackend')
            }
          ]
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: true
    enableIPForwarding: false
  }
}

//creating network interface for web tier - nisweb002
resource nisweb002 'Microsoft.Network/networkInterfaces@2022-07-01' = {
  name: nis_web_tier_002
  location: location
  dependsOn: [
    vn, lb
  ]
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfiguration001'
        properties: {
          privateIPAddress: '10.0.1.5'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet, 'web-tier-subnet')
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lb_internal, 'webtierbackend')
            }
          ]
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: true
    enableIPForwarding: false
  }
}

//Creating subnet app tier - subnet_app
resource subnet_app 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' = {
  name: concat(vnet, '/app-tier-subnet')
  dependsOn: [
    vn, nsg_app
  ]
  properties: {
    addressPrefix: '10.0.7.0/24'
    networkSecurityGroup: {
      id: resourceId('Microsoft.Network/networkSecurityGroups', nsg_app_tier)
    }
    delegations: []
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

//Creating subnet db tier - subnet_db
resource subnet_db 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' = {
  name: concat(vnet, '/db-tier-subnet')
  dependsOn: [
    vn, nsg_db
  ]
  properties: {
    addressPrefix: '10.0.13.0/24'
    networkSecurityGroup: {
      id: resourceId('Microsoft.Network/networkSecurityGroups', nsg_db_tier)
    }
    delegations: []
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

//Creating subnet jump tier - subnet_jump
resource subnet_jumo 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' = {
  name: concat(vnet, '/jump-subnet')
  dependsOn: [
    vn, nsg_jump
  ]
  properties: {
    addressPrefix: '10.0.0.0/24'
    networkSecurityGroup: {
      id: resourceId('Microsoft.Network/networkSecurityGroups', nsg_jump_vm)
    }
    delegations: []
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

//Creating subnet web tier - subnet_web
resource subnet_web 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' = {
  name: concat(vnet, '/web-tier-subnet')
  dependsOn: [
    vn, nsg_web
  ]
  properties: {
    addressPrefix: '10.0.1.0/24'
    networkSecurityGroup: {
      id: resourceId('Microsoft.Network/networkSecurityGroups', nsg_web_tier)
    }
    delegations: []
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

//Creating virtual mechine - jumpVM
resource vm_jump 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: jumpVM
  location: location
  dependsOn: [
    nisjumpvm
  ]
  properties:{
    hardwareProfile:{
      vmSize: 'Standard_DS11_v2'
    }
    storageProfile:{
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku:'2016-DataCenter-Server-Core'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        name: concat(jumpVM,'-osdisk-ffg45gr45r')
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk:{
          storageAccountType: 'StandardSSD_LRS'
          id:resourceId('Microsoft.Compute/disks',concat(jumpVM,'-osdisk-ffg45gr45r'))
        }
        diskSizeGB: 127
      }
      dataDisks: []
    }
    osProfile:{
      computerName: jumpVM
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration:{
        provisionVMAgent:true
        enableAutomaticUpdates: true
        patchSettings:{
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
          enableHotpatching: false
        }
      }
      secrets: []
      allowExtensionOperations: true
      requireGuestProvisionSignal: true
    }
    networkProfile:{
      networkInterfaces: [
        {
          id: nisjumpvm.id
          
        }
      ]
    }
    diagnosticsProfile:{
      bootDiagnostics:{
        enabled: true
      }
    }
  }
}

//Creating virtual mechine - app-vm-01
resource app_vm_01 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vm_app_1
  location: location
  dependsOn: [
    nisapp001
  ]
  properties:{
    hardwareProfile:{
      vmSize: 'Standard_DS11_v2'
    }
    storageProfile:{
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku:'2016-DataCenter-Server-Core'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        name: concat(vm_app_1,'-osdisk-ffg45gr47r')
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk:{
          storageAccountType: 'StandardSSD_LRS'
          id:resourceId('Microsoft.Compute/disks',concat(vm_app_1,'-osdisk-ffg45gr47r'))
        }
        diskSizeGB: 127
      }
      dataDisks: []
    }
    osProfile:{
      computerName: vm_app_1
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration:{
        provisionVMAgent:true
        enableAutomaticUpdates: true
        patchSettings:{
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
          enableHotpatching: false
        }
      }
      secrets: []
      allowExtensionOperations: true
      requireGuestProvisionSignal: true
    }
    networkProfile:{
      networkInterfaces: [
        {
          id: nisapp001.id
          
        }
      ]
    }
    diagnosticsProfile:{
      bootDiagnostics:{
        enabled: true
      }
    }
  }
}

//Creating virtual mechine - app-vm-02
resource app_vm_02 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vm_app_2
  location: location
  dependsOn: [
    nisapp001
  ]
  properties:{
    hardwareProfile:{
      vmSize: 'Standard_DS11_v2'
    }
    storageProfile:{
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku:'2016-DataCenter-Server-Core'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        name: concat(vm_app_2,'-osdisk-ffg45gr47rr')
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk:{
          storageAccountType: 'StandardSSD_LRS'
          id:resourceId('Microsoft.Compute/disks',concat(vm_app_2,'-osdisk-ffg45gr47rr'))
        }
        diskSizeGB: 127
      }
      dataDisks: []
    }
    osProfile:{
      computerName: vm_app_2
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration:{
        provisionVMAgent:true
        enableAutomaticUpdates: true
        patchSettings:{
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
          enableHotpatching: false
        }
      }
      secrets: []
      allowExtensionOperations: true
      requireGuestProvisionSignal: true
    }
    networkProfile:{
      networkInterfaces: [
        {
          id: nisapp002.id
          
        }
      ]
    }
    diagnosticsProfile:{
      bootDiagnostics:{
        enabled: true
      }
    }
  }
}

//Creating virtual mechine - db-vm-01
resource db_vm_01 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vm_db_1
  location: location
  dependsOn: [
    nisapp001
  ]
  properties:{
    hardwareProfile:{
      vmSize: 'Standard_DS11_v2'
    }
    storageProfile:{
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku:'2016-DataCenter-Server-Core'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        name: concat(vm_db_1,'-osdisk-ffg45gr47rrT')
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk:{
          storageAccountType: 'StandardSSD_LRS'
          id:resourceId('Microsoft.Compute/disks',concat(vm_db_1,'-osdisk-ffg45gr47rrT'))
        }
        diskSizeGB: 127
      }
      dataDisks: []
    }
    osProfile:{
      computerName: vm_db_1
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration:{
        provisionVMAgent:true
        enableAutomaticUpdates: true
        patchSettings:{
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
          enableHotpatching: false
        }
      }
      secrets: []
      allowExtensionOperations: true
      requireGuestProvisionSignal: true
    }
    networkProfile:{
      networkInterfaces: [
        {
          id: nisdb001.id
          
        }
      ]
    }
    diagnosticsProfile:{
      bootDiagnostics:{
        enabled: true
      }
    }
  }
}

//Creating virtual mechine - db-vm-02
resource db_vm_02 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vm_db_1
  location: location
  dependsOn: [
    nisapp001
  ]
  properties:{
    hardwareProfile:{
      vmSize: 'Standard_DS11_v2'
    }
    storageProfile:{
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku:'2016-DataCenter-Server-Core'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        name: concat(vm_db_2,'-osdisk-ffg45gr47rrT1')
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk:{
          storageAccountType: 'StandardSSD_LRS'
          id:resourceId('Microsoft.Compute/disks',concat(vm_db_2,'-osdisk-ffg45gr47rrT1'))
        }
        diskSizeGB: 127
      }
      dataDisks: []
    }
    osProfile:{
      computerName: vm_db_2
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration:{
        provisionVMAgent:true
        enableAutomaticUpdates: true
        patchSettings:{
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
          enableHotpatching: false
        }
      }
      secrets: []
      allowExtensionOperations: true
      requireGuestProvisionSignal: true
    }
    networkProfile:{
      networkInterfaces: [
        {
          id: nisdb002.id
          
        }
      ]
    }
    diagnosticsProfile:{
      bootDiagnostics:{
        enabled: true
      }
    }
  }
}

//Creating virtual mechine - web-vm-01
resource web_vm_01 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vm_web_1
  location: location
  dependsOn: [
    nisapp001
  ]
  properties:{
    hardwareProfile:{
      vmSize: 'Standard_DS11_v2'
    }
    storageProfile:{
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku:'2016-DataCenter-Server-Core'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        name: concat(vm_web_1,'-osdisk-ffg45gr47rrT2')
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk:{
          storageAccountType: 'StandardSSD_LRS'
          id:resourceId('Microsoft.Compute/disks',concat(vm_web_1,'-osdisk-ffg45gr47rrT2'))
        }
        diskSizeGB: 127
      }
      dataDisks: []
    }
    osProfile:{
      computerName: vm_web_1
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration:{
        provisionVMAgent:true
        enableAutomaticUpdates: true
        patchSettings:{
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
          enableHotpatching: false
        }
      }
      secrets: []
      allowExtensionOperations: true
      requireGuestProvisionSignal: true
    }
    networkProfile:{
      networkInterfaces: [
        {
          id: nisweb001.id
          
        }
      ]
    }
    diagnosticsProfile:{
      bootDiagnostics:{
        enabled: true
      }
    }
  }
}

//Creating virtual mechine - web-vm-02
resource web_vm_02 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vm_web_2
  location: location
  dependsOn: [
    nisapp001
  ]
  properties:{
    hardwareProfile:{
      vmSize: 'Standard_DS11_v2'
    }
    storageProfile:{
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku:'2016-DataCenter-Server-Core'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        name: concat(vm_web_2,'-osdisk-ffg45gr47rrT3')
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk:{
          storageAccountType: 'StandardSSD_LRS'
          id:resourceId('Microsoft.Compute/disks',concat(vm_web_2,'-osdisk-ffg45gr47rrT3'))
        }
        diskSizeGB: 127
      }
      dataDisks: []
    }
    osProfile:{
      computerName: vm_web_2
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration:{
        provisionVMAgent:true
        enableAutomaticUpdates: true
        patchSettings:{
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
          enableHotpatching: false
        }
      }
      secrets: []
      allowExtensionOperations: true
      requireGuestProvisionSignal: true
    }
    networkProfile:{
      networkInterfaces: [
        {
          id: nisweb002.id
          
        }
      ]
    }
    diagnosticsProfile:{
      bootDiagnostics:{
        enabled: true
      }
    }
  }
}

//Creating network security rules - JUMP VM
resource net_sec_jump 'Microsoft.Network/networkSecurityGroups/securityRules@2022-07-01' = {
  name: concat(nsg_jump_vm, '/port_8080')
  dependsOn: [
    nsg_jump
  ]
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '3389'
    sourceAddressPrefix: '49.37.167.48'
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 100
    direction: 'Inbound'
    sourcePortRanges: []
    destinationPortRanges: []
    sourceAddressPrefixes: []
    destinationAddressPrefixes: []
  }
}

//Creating availablity set for db tier
resource as_db 'Microsoft.Compute/availabilitySets@2022-08-01' = {
  name: as_db_tier
  location: location
  dependsOn: [
    db_vm_01, db_vm_02
  ]
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformUpdateDomainCount: 5
    platformFaultDomainCount: 2
    virtualMachines: [
      {
        id: db_vm_01.id
      }
      {
        id: db_vm_02.id
      }
    ]
  }
}

//Creating availablity set for app tier
resource as_app 'Microsoft.Compute/availabilitySets@2022-08-01' = {
  name: as_app_tier
  location: location
  dependsOn: [
    app_vm_01, app_vm_02
  ]
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformUpdateDomainCount: 5
    platformFaultDomainCount: 2
    virtualMachines: [
      {
        id: app_vm_01.id
      }
      {
        id: app_vm_02.id
      }
    ]
  }
}

//Creating availablity set for db tier
resource as_web 'Microsoft.Compute/availabilitySets@2022-08-01' = {
  name: as_web_tier
  location: location
  dependsOn: [
    web_vm_01, web_vm_02
  ]
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformUpdateDomainCount: 5
    platformFaultDomainCount: 2
    virtualMachines: [
      {
        id: web_vm_01.id
      }
      {
        id: web_vm_02.id
      }
    ]
  }
}
