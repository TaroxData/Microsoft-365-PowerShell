# Falls das Modul noch nicht installiert ist
Set-Executionpolicy bypass
Install-Module Microsoft.Graph -Scope CurrentUser

# Verbindung zu Microsoft Graph
Connect-MgGraph -Scopes "User.ReadWrite.All"

$UPN = "Max.Mustermann@Musterfirma.de"

# AD-Benutzer anhand der UPN holen
$ADUser = Get-ADUser -Filter "UserPrincipalName -eq '$UPN'" -Properties ObjectGUID

if (-not $ADUser) {
    Write-Error "Kein AD-Benutzer mit der UPN '$UPN' gefunden."
    return
}

# ImmutableID aus dem ObjectGUID bilden
$ImmutableID = [System.Convert]::ToBase64String($ADUser.ObjectGUID.ToByteArray())

# On-Premises Immutable ID im Cloud-Benutzer setzen
Update-MgUser -UserId $UPN -OnPremisesImmutableId $ImmutableID

# Kontrolle
Get-MgUser -UserId $UPN -Property UserPrincipalName,OnPremisesImmutableId | Select-Object UserPrincipalName, OnPremisesImmutableId
