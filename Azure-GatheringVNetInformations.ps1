################################################################################################
#
#    Author : Ludovic DOUAUD
#
#    Script name : Azure-GatheringVNetInformations_v3.ps1
#
#    Creation date : 2024.05.24
#    Change log
#        v1 :    Get VNet informations
#        v2 :    Add Subnets adresses spaces informations + Export CSV
#        v3 :    Add Vnet peering informations
#                Add input parameters
#
################################################################################################


# Parameters management
param(
    # Parameter TenantID mandatory
    [Parameter(Mandatory)] [string] $TenantId,

    # Parameter workspace mandatory
    [Parameter(Mandatory)] [string] $WorkspacePath
)


# Array initialisation
$AllSubnetArray = @()
$AllVnetPeeringArray = @() 
#$VnetPeeringInfo = @{ "Subscription Name"="" ;"Subscription ID"="" ;"VNet"="" ; "Peering Name"="" ; "Remote VNet ID"="" ; "Remote VNet Name"="" ; "Peering State"="" ; "Allow Virtual Network Access"="" ; "Allow Forwarded Traffic"="" ; "Allow Gateway Transit"="" ; "Use Remote Gateways"=""}


# AZURE CONNECTION
# Connect to Azure tenant
Connect-AzAccount -TenantId $TenantId
 
# Get all subsciptions
$SubscriptionsList = Get-AzSubscription -TenantId $TenantId


## AZURE GATHERING INFORMATIONS
# Browse all subscriptions
foreach ($Subscription in $SubscriptionsList)
{
    #$Subscription = "8f20464e-debe-4db4-9d72-d7f866edf4d5"

    # Set the Subscription as context
    Set-AzContext -Subscription $Subscription

    # Get all VNet
    $VnetList = Get-AzVirtualNetwork

    # Browse each VNet of the subscription
    foreach ($Vnet in $VnetList)
    {  
        # Get all peering of the VNet
        $VnetPeeringList = $Vnet.VirtualNetworkPeerings
        #$VnetPeeringNameList = Get-AzVirtualNetworkPeering -VirtualNetworkName $Vnet.Name -ResourceGroupName $Vnet.ResourceGroupName

        # Browse each Peering of the VNet
        foreach ($VnetPeering in $VnetPeeringList)
        {  
            
            ## Fill Subnets array
            # Solution A - Not respect column order
            #$VnetPeeringInfo.'Subscription Name' = $Subscription.Name
            #$VnetPeeringInfo.'Subscription ID' = $Subscription.id
            #$VnetPeeringInfo.'VNet' = $Vnet.Name
            #$VnetPeeringInfo.'Peering Name' = $VnetPeering.Name
            #$VnetPeeringInfo.'Remote VNet ID' = $VnetPeering.RemoteVirtualNetwork.Id
            #$VnetPeeringInfo.'Remote VNet Name' = $VnetPeering.RemoteVirtualNetwork.Id.split("/")[-1]
            #$VnetPeeringInfo.'Peering State' = $VnetPeering.PeeringState
            #$VnetPeeringInfo.'Allow Virtual Network Access' = $VnetPeering.AllowVirtualNetworkAccess
            #$VnetPeeringInfo.'Allow Forwarded Traffic' = $VnetPeering.AllowForwardedTraffic
            #$VnetPeeringInfo.'Allow Gateway Transit' = $VnetPeering.AllowGatewayTransit
            #$VnetPeeringInfo.'Use Remote Gateways' = $VnetPeering.UseRemoteGateways
            #$TempPSObject=New-Object PSObject -Property $VnetPeeringInfo
            #$AllVnetPeeringArray +=$TempPSObject

            #write-host "VnetPeering.RemoteVirtualNetwork.Id="$($VnetPeering.RemoteVirtualNetwork.Id)
            #$RVnet = $(Get-AzResource | Where-Object ResourceId -EQ $($VnetPeering.RemoteVirtualNetwork.Id))
            #write-host "Remote VNet" = $RVnet
            #write-host "Remote VNet name" = $RVnet.Name

            # Solution B - Respect column order
            $AllVnetPeeringArray += @(
                [pscustomobject]@{
                    'Subscription Name'=$($Subscription.Name);
                    'Subscription ID'=$($Subscription.id);
                    VNet=$($Vnet.Name);
                    'Peering Name'=$VnetPeering.Name;
                    'Remote VNet ID'=$VnetPeering.RemoteVirtualNetwork.Id;
                    'Remote VNet Name'=$VnetPeering.RemoteVirtualNetwork.Id.split("/")[-1];
                    'Peering State'=$VnetPeering.PeeringState;
                    'Allow Virtual Network Access'=$VnetPeering.AllowVirtualNetworkAccess;
                    'Allow Forwarded Traffic'=$VnetPeering.AllowForwardedTraffic;
                    'Allow Gateway Transit'=$VnetPeering.AllowGatewayTransit;
                    'Use Remote Gateways'=$VnetPeering.UseRemoteGateways
                }
            )
        }
                
       
        # Browse each Subnet of the VNet
        foreach ($Subnet in $Vnet.Subnets)
        {
            # Fill Subnets array
            $AllSubnetArray += @(
                [pscustomobject]@{
                    SubscriptionName=$($Subscription.Name);
                    SubscriptionId=$($Subscription.id);
                    VNetResourceGroupName=$($Vnet.ResourceGroupName);
                    VNetName=$($Vnet.Name);
                    SubnetName=$($Subnet.Name);
                    AdressPrefix=$($Subnet.AddressPrefix)
                }
            )
        }   
    }
}

# Display arrays
$AllVnetPeeringArray | Format-Table "Subscription Name" , "Subscription Id" , "VNet" , "Peering Name","Remote VNet Name","Peering State","Allow Virtual Network Access","Allow Forwarded Traffic","Allow Gateway Transit","Use Remote Gateways"
$AllSubnetArray | Format-Table -Property SubscriptionName, SubscriptionId, VNetResourceGroupName, VNetName, SubnetName, AdressPrefix

# Export Array to CSV files
$AllVnetPeeringArray | Export-Csv $WorkspacePath"\"$TenantId"_"$(Get-Date -Format yyyy.MM.dd-HH.mm.ss)"_VNetPeeringList.csv" -NoTypeInformation
$AllSubnetArray | Export-Csv $WorkspacePath"\"$TenantId"_"$(Get-Date -Format yyyy.MM.dd-HH.mm.ss)"_SubnetList.csv" -NoTypeInformation