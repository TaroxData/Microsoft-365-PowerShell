#Mit diesem Skript kann bei allen aktuellen GDAP-Beziehungen der Schalter "auto extend" aktiviert werden.
#Je nach Anzahl der Kundenbeziehungen kann das Skript etwas Zeit in Anspruch nehmen, ~ 4 Sekunden pro Beziehung.
#Die App-Registirerungsanfrage für Microsoft Graph muss bei der Anmeldung mit einem Admin-Account akzeptiert werden.

$moduleName = Microsoft.Graph.Identity.Partner
if ($moduleName -and -not (Get-Module -ListAvailable -Name $moduleName)) {
    Write-Host "Das Modul $moduleName ist nicht installiert. Installation wird durchgeführt..."
    Install-Module -Name $moduleName -Scope CurrentUser -Force
} 
else ($moduleName) {
    Write-Host "Das Modul $moduleName ist bereits installiert."
} 

$scopes = @("User.Read.All", "Directory.Read.All", "DelegatedAdminRelationship.ReadWrite.All")
Connect-MGGraph -Scopes $scopes

#Get all GDAP-relationships
$GDAPrelationships = Get-MgTenantRelationshipDelegatedAdminRelationship -All
$GDAPrelationshipsCount = $GDAPrelationships.Count
$i = 0

while ($i -ine $GDAPrelationshipsCount) {
	$GDAPrelationship = $GDAPrelationships[$i]
	$delegatedAdminRelationshipId = $GDAPrelationship.Id
	$tenantId = $GDAPrelationship.customer.tenantId
	$displayName = $GDAPrelationship.DisplayName
	$durationDays = "P{0}D" -f $gdaprelationship.Duration.Days

	if ($GDAPrelationship.Status -eq "active" -and $GDAPrelationship.AutoExtendDuration.Days -eq "0") {
		
		$params = @{
			displayName = "$displayName"
			duration = "$durationDays"
			customer = @{
				tenantId = "$tenantId"
			}
			accessDetails = @{
				unifiedRoles = @()
			}
			autoExtendDuration = "P180D"
		}
		foreach ($role in $GDAPrelationship.AccessDetails.UnifiedRoles) {
			$params.accessDetails.unifiedRoles += @{
				roleDefinitionId = $role.RoleDefinitionId
			}
		}

		Update-MgTenantRelationshipDelegatedAdminRelationship -DelegatedAdminRelationshipId $delegatedAdminRelationshipId -BodyParameter $params -Headers @{ "If-Match" = $GDAPrelationship.AdditionalProperties['@odata.etag']}
	}
	$i++
	Start-Sleep -Seconds 1
}
