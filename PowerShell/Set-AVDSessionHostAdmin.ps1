# script to add user to local administrators group and assign them a session host

# Connect-azaccount

# set variables
$subscription = "<subscription>"
$resourceGroup = "<rg>"
$hostPoolName = "<hostpool>"

$userName = "<user_name>" # for active directory users
$domainName = "<domain_name>" # active directory domain
$domainSuffix = "<domain_suffix>" # active directory domain suffix
$userUPN = "<user_upn>" # for entra id users

$VMName = "<vm_name>" # specific session host vm to assign user

$AADJoin = $true # entra join when true or active directory join when false
$assignUser = $true # assigns user to a session host when true
$assignAvailable = $true # selects the first available vm when true or the specified vm ($VMame) when false

# set az context
Set-AzContext -Subscription $Subscription

# get VMName of first available VM if assign next avaiable is set
if ($assignAvailable)
{
    $VMName = Get-AzWvdSessionHost -HostPoolName $hostPoolName -ResourceGroupName $resourceGroup | Where-Object -Property AssignedUser -EQ $null | Select-Object -Property Name -ExpandProperty Name -First 1
    $VMName = $VMName.Replace("$hostPoolName/","")
    $VMName = $VMName.Replace($(".$domainName"+$domainSuffix),"")
}

# check for AADJ or ADJ 
if ($AADJoin)
{
    # set session host name AADJ
    $sessionHostName = $VMName

    # run script to add user to local admin AADJ 
    Invoke-AzVMRunCommand -ResourceGroupName $resourceGroup -VMName $VMName -CommandId 'RunPowerShellScript' -ScriptString "Add-LocalGroupMember -Group ""Administrators"" -Member ""azure\$($userUPN)"""
}
else 
{
    # set session host name ADJ
    $sessionHostName = "$($VMName).$($domainName)$($domainSuffix)"

    # run script to add user to local admin ADJ
    Invoke-AzVMRunCommand -ResourceGroupName $resourceGroup -VMName $VMName -CommandId 'RunPowerShellScript' -ScriptString "Add-LocalGroupMember -Group ""Administrators"" -Member ""$($domainName)\$($userName)"""
}

# check and assign user to AVD session host
if ($assignUser)
{
    # assign user to AVD session host
    Update-AzWvdSessionHost -HostPoolName $hostPoolName -Name $sessionHostName -ResourceGroupName $resourceGroup -AssignedUser $userUPN
}