function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error", "Gray")][string]$Level = "Info"
    )

    switch ($Level) {
        "Info"    { Write-Host $Message -ForegroundColor Cyan }
        "Success" { Write-Host $Message -ForegroundColor Green }
        "Warning" { Write-Host $Message -ForegroundColor Yellow }
        "Error"   { Write-Host $Message -ForegroundColor Red }
        "Gray"    { Write-Host $Message -ForegroundColor DarkGray }
    }
}

function Ensure-Module {
    param (
        [Parameter(Mandatory)][string]$Name
    )

    if (-not (Get-Module -ListAvailable -Name $Name)) {
        Write-Log "Modul '$Name' ist nicht installiert. Versuche, es zu installieren..." -Level Warning
        try {
            Install-Module -Name $Name -Force -Scope CurrentUser -AllowClobber
        } catch {
            Write-Log "Fehler beim Installieren des Moduls '$Name': $_" -Level Error
            exit 1
        }
    }

    try {
        Import-Module $Name -Force -ErrorAction Stop
        Write-Log "Modul '$Name' erfolgreich geladen." -Level Success
    } catch {
        Write-Log "Fehler beim Laden des Moduls '$Name': $_" -Level Error
        exit 1
    }
}

function Connect-ExchangeOnlineIfNeeded {
    try {
        $exoConn = Get-ConnectionInformation -ErrorAction Stop
    } catch {
        $exoConn = $null
    }

    if (-not $exoConn -or $exoConn.State -ne "Connected") {
        Write-Log "Stelle Verbindung zu Exchange Online her..." -Level Info
        try {
            Connect-ExchangeOnline -ErrorAction Stop
            Write-Log "Erfolgreich mit Exchange Online verbunden." -Level Success
        } catch {
            Write-Log "Fehler beim Verbinden mit Exchange Online: $_" -Level Error
            exit 1
        }
    } else {
        Write-Log "Bereits mit Exchange Online verbunden." -Level Gray
    }
}

function Connect-AIPIfNeeded {
    if (-not (Get-AipServiceConfiguration -ErrorAction SilentlyContinue)) {
        Write-Log "Stelle Verbindung zu AIPService her..." -Level Info
        try {
            Connect-AipService -ErrorAction Stop
            Write-Log "Erfolgreich mit AIPService verbunden." -Level Success
        } catch {
            Write-Log "Fehler beim Verbinden mit AIPService: $_" -Level Error
            exit 1
        }
    } else {
        Write-Log "Bereits mit AIPService verbunden." -Level Gray
    }
}

function Enable-AIPIfDisabled {
    try {
        $serviceStatus = Get-AipService -ErrorAction Stop
        if ($serviceStatus.Enabled -ne $true) {
            Write-Log "AIPService ist deaktiviert. Aktiviere AIPService..." -Level Warning
            Enable-AipService
            Write-Log "AIPService erfolgreich aktiviert." -Level Success
        } else {
            Write-Log "AIPService ist bereits aktiviert." -Level Gray
        }
    } catch {
        Write-Log "Fehler beim Abrufen des AIPService-Status: $_" -Level Error
        exit 1
    }
}

function Configure-IRM {
    Write-Log "Lese aktuelle IRM-Konfiguration..." -Level Info

    try {
        $irmConfig = Get-IRMConfiguration -ErrorAction Stop
        $licensingLocation = (Get-AadrmConfiguration -ErrorAction Stop).LicensingIntranetDistributionPointUrl

        Write-Log "Setze IRM-Konfiguration..." -Level Info
        Set-IRMConfiguration `
            -InternalLicensingEnabled $true `
            -AzureRMSLicensingEnabled $true `
            -SimplifiedClientAccessEnabled $true `
            -LicensingLocation $licensingLocation

        Write-Log "IRM-Konfiguration abgeschlossen, hier die neu gesetzten Einstellungen:" -Level Success
        $irmConfig = Get-IRMConfiguration -ErrorAction Stop
        Write-Output $irmConfig
    } catch {
        Write-Log "Fehler bei der IRM-Konfiguration: $_" -Level Error
        exit 1
    }
}

Ensure-Module -Name ExchangeOnlineManagement
Ensure-Module -Name AIPService

Connect-ExchangeOnlineIfNeeded
Connect-AIPIfNeeded

Enable-AIPIfDisabled
Configure-IRM