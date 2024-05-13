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
