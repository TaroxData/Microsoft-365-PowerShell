# Define registry path and value
$registryPath = "HKCU:\Software\Policies\Microsoft\office\16.0\outlook\preferences"
$valueName = "NewOutlookMigrationUserSetting"
$valueData = 0

function setRegistryKey {
    # Create the registry path and set the DWORD value to 0
    Write-Output "Creating registry path and setting $valueName to $valueData in $registryPath"
    New-Item -Path $registryPath -Force | Out-Null
    Set-ItemProperty -Path $registryPath -Name $valueName -Value $valueData -Type DWord

    Write-Output "Registry key and value have been set successfully."
}

# Check if the registry path exists
if (Test-Path $registryPath) {
    # Check if the DWORD value exists
    $value = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue
    if ($null -ne $value) {
        # Check if the value is set to 0
        if ($value.$valueName -eq 0) {
            exit 0
        }
        else {
            setRegistryKey
        }
    }
    else {
        # DWORD does not exist
        setRegistryKey
    }
}
else {
    # Registry path does not exist
    setRegistryKey
}
