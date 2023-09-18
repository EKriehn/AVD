# script to retrieve a list of all avd hostpools, with associated resource groups and subscriptions, and output to a .csv file.

# Connect-azaccount

# set variables
$outputFile = ".\avd_hostpool_inventory.csv"
$hostPoolList = @()

# define hostpool class
class HostPool {
    [string]$name
    [string]$resourceGroup
    [string]$subscription;
}

# get available subscriptions
$subscriptions = Get-AzSubscription

# iterate available subscriptions and resource groups and update the list of associated avd hostpools
foreach ($subscription in $subscriptions)
{
    Set-AzContext -Subscription $subscription
    $resourceGroups = Get-AzResourceGroup

    foreach ($resourceGroup in $resourceGroups)
    {
        $hostPool = Get-AzWvdHostPool -ResourceGroupName $($resourceGroup.ResourceGroupName)
        
        if ($null -ne $hostPool)
        {
            $newHostPool = New-Object HostPool
            $newHostPool.Name = $hostPool.Name
            $newHostPool.resourceGroup = $resourceGroup.ResourceGroupName
            $newHostPool.subscription = $subscription

            $hostPoolList += $newHostpool
        }
    }
}

# output the list of avd hostpools
$hostPoolList | ConvertTo-Csv | Out-File -FilePath $outputFile
