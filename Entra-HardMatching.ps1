Import-Module ActiveDirectory
Connect-AzureAD

$ou = "OU=Beispiel,DC=domain,DC=com"
$users = Get-ADUser -Filter * -SearchBase $ou -Properties UserPrincipalName

foreach ($user in $users) {
    $UPN = $user.UserPrincipalName
    $Name = $user.Name
    $ImmutableID = [System.Convert]::ToBase64String($user.ObjectGUID.ToByteArray())
    $ObjectID = (Get-AzureADUser -SearchString $Name).ObjectId
    Set-AzureADUser -ObjectId $ObjectID -ImmutableId $ImmutableID
    Write-Host "Immutable ID von $Name wurde in Entra gesetzt."
}
Start-ADSyncSyncCycle -PolicyType Delta
