targetScope = 'resourceGroup'

@description('Project short name')
param project string

@description('Environment name')
param environment string

@description('Azure region')
param location string

@description('VM size SKU')
param vmSize string

@description('CIDR for VNet A')
param vnetACidr string

@description('CIDR for VNet B')
param vnetBCidr string

@description('App subnet CIDR for VNet A')
param subnetAApp string

@description('App subnet CIDR for VNet B')
param subnetBApp string

@description('VM plan list. Each item: name, vnet, osType')
param vmPlan array

param adminUsername string = 'azureuser'
@secure()
param adminPassword string


var namePrefix = '${project}-${environment}'
var vmNames = [for vm in vmPlan: vm.name]


resource vnetA 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: '${namePrefix}-vnet-a'
  location: location
  tags: {
    Project: project
    Environment: environment
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetACidr
      ]
    }
    subnets: [
      {
        name: 'app'
        properties: {
          addressPrefix: subnetAApp
        }
      }
    ]
  }
}

resource vnetB 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: '${namePrefix}-vnet-b'
  location: location
  tags: {
    Project: project
    Environment: environment
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetBCidr
      ]
    }
    subnets: [
      {
        name: 'app'
        properties: {
          addressPrefix: subnetBApp
        }
      }
    ]
  }
}

resource vmNics 'Microsoft.Network/networkInterfaces@2023-11-01' = [for vm in vmPlan: {
  name: '${namePrefix}-${vm.name}-nic'
  location: location
  tags: {
    Project: project
    Environment: environment
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: (toUpper(string(vm.vnet)) == 'A')
              ? '${vnetA.id}/subnets/app'
              : '${vnetB.id}/subnets/app'
          }
        }
      }
    ]
  }
}]

resource peeringAtoB 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  parent: vnetA
  name: 'peer-a-to-b'
  properties: {
    remoteVirtualNetwork: {
      id: vnetB.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

resource peeringBtoA 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {
  parent: vnetB
  name: 'peer-b-to-a'
  properties: {
    remoteVirtualNetwork: {
      id: vnetA.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

resource linuxVms 'Microsoft.Compute/virtualMachines@2023-09-01' = [for (vm, i) in vmPlan: if (toLower(string(vm.osType)) == 'linux') {
  name: '${namePrefix}-${vm.name}'
  location: location
  tags: {
    Project: project
    Environment: environment
    OSType: 'linux'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: '${namePrefix}-${vm.name}'
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNics[i].id
          properties: {
            primary: true
          }
        }
      ]
    }
  }
}]

resource windowsVms 'Microsoft.Compute/virtualMachines@2023-09-01' = [for (vm, i) in vmPlan: if (toLower(string(vm.osType)) == 'windows') {
  name: '${namePrefix}-${vm.name}'
  location: location
  tags: {
    Project: project
    Environment: environment
    OSType: 'windows'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: '${namePrefix}-${vm.name}'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNics[i].id
          properties: {
            primary: true
          }
        }
      ]
    }
  }
}]

output contractCheck object = {
  namePrefix: namePrefix
  location: location
  vmSize: vmSize
  vnetA: vnetACidr
  vnetB: vnetBCidr
  subnetA: subnetAApp
  subnetB: subnetBApp
  vmCount: length(vmPlan)
  vmNames: vmNames
}

