#!/bin/bash

az account set --subscription="c9a9a3de-1754-4e2c-a16c-29775ca235d3"
$VmRgName="quickTools"
$Location="westus"  


# Create a Virtual Network for the VMs
echo '------------------------------------------'
echo 'Creating a Virtual Network for the VMs'
# az network vnet create 
#     --resource-group $RgName 
#     --$Location $Location 
#     --name quickVnet 
#     --subnet-name quickVM_Snet3

# Create a Network Security Group
echo '------------------------------------------'
echo 'Creating a Network Security Group'
az network nsg create --resource-group $VmRgName --name quickNSG --Location $Location

az network nsg rule create -g $VmRgName --nsg-name quickNSG -n AllowAll80 --priority 101 --source-address-prefixes 'Internet' --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 80 --access Allow --protocol Tcp --description "Allow all port 80 traffic"


# Create the NIC
for i in `seq 1 2`; do
  echo '------------------------------------------'
  echo 'Creating webNic'$i
  az network nic create     --resource-group $VmRgName     --name webNic$i     --vnet-name quickVnet     --subnet quickVM_Snet3     --network-security-group quickNSG     --$Location $Location
done 

# Create an availability set
echo '------------------------------------------'
echo 'Creating an availability set'
az vm availability-set create     --resource-group $VmRgName     --name quickAvailabilitySet

# Create 2 VM's from a template
for i in `seq 1 2`; do
    echo '------------------------------------------'
    echo 'Creating webVM'$i
    az vm create         --admin-username quick         --resource-group $VmRgName         --name webVM$i         --nics webNic$i         --$Location $Location         --image Ubuntu2204         --availability-set quickAvailabilitySet         --generate-ssh-keys         --custom-data cloud-init.txt
done

# Done
echo '--------------------------------------------------------'
echo '             VM Setup Completed'
echo '--------------------------------------------------------'

echo '--------------------------------------------------------'
echo '             Starting Load Balancer Deploy'
echo '--------------------------------------------------------'


    az network public-ip create       --resource-group $VmRgName       --$Location $Location       --al$Location-method Static       --name myPublicIP       --sku Standard

   az network lb create       --resource-group $VmRgName       --name myLoadBalancer       --public-ip-address myPublicIP       --frontend-ip-name myFrontEndPool       --backend-pool-name myBackEndPool       --sku Standard

  az network lb probe create      --resource-group $VmRgName      --lb-name myLoadBalancer      --name myHealthProbe      --protocol tcp      --port 80

  az network lb rule create       --resource-group $VmRgName       --lb-name myLoadBalancer       --name myHTTPRule       --protocol tcp       --frontend-port 80       --backend-port 80       --frontend-ip-name myFrontEndPool       --backend-pool-name myBackEndPool
  az network nic ip-config update       --resource-group $VmRgName       --nic-name webNic1       --name ipconfig1       --lb-name myLoadBalancer       --lb-address-pools myBackEndPool

  az network nic ip-config update       --resource-group $VmRgName       --nic-name webNic2       --name ipconfig1       --lb-name myLoadBalancer       --lb-address-pools myBackEndPool

  az network public-ip show       --resource-group $VmRgName       --name myPublicIP       --query [ipAddress]       --output tsv

echo '--------------------------------------------------------'
echo '  Load balancer deployed to the IP Address shown above'
echo '--------------------------------------------------------'











