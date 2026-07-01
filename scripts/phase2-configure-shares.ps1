# =============================================================================
# Lab 3 - Phase 2: Configure SMB Shares and NTFS Permissions
# Runs on: FS01
# Note: FS01 must be domain-joined before running this phase
# =============================================================================
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
Write-Host "=== Phase 2: Configuring SMB Shares and NTFS Permissions ===" -ForegroundColor Cyan

$domain   = "LAB"
$basePath = "C:\Shares"

Write-Host "Creating share folders..." -ForegroundColor Yellow
New-Item -Path $basePath -ItemType Directory -Force | Out-Null

foreach ($folder in @("Finance","HR","Sales","IT")) {
    New-Item -Path "$basePath\$folder" -ItemType Directory -Force | Out-Null
    if (-not (Get-SmbShare -Name $folder -ErrorAction SilentlyContinue)) {
        New-SmbShare -Name $folder -Path "$basePath\$folder" -FullAccess "Everyone"
        Write-Host "  [+] SMB Share created: $folder" -ForegroundColor Green
    } else {
        Write-Host "  [~] SMB Share already exists: $folder" -ForegroundColor Yellow
    }
}

function Set-FolderPermissions {
    param($path, $permissions)
    icacls $path /inheritance:d | Out-Null
    icacls $path /remove "BUILTIN\Users" | Out-Null
    icacls $path /remove "Everyone" | Out-Null
    icacls $path /remove "NT AUTHORITY\Authenticated Users" | Out-Null
    foreach ($p in $permissions) {
        icacls $path /grant "$($p.Identity)`:$($p.Rights)" | Out-Null
        Write-Host "  [+] $($p.Identity) --> $($p.Rights)" -ForegroundColor Green
    }
}

Write-Host "Setting NTFS permissions: Finance" -ForegroundColor Yellow
Set-FolderPermissions -path "$basePath\Finance" -permissions @(
    @{Identity="$domain\GRP_Finance";    Rights="(OI)(CI)M"},
    @{Identity="$domain\GRP_HR";         Rights="(OI)(CI)R"},
    @{Identity="$domain\GRP_IT";         Rights="(OI)(CI)F"},
    @{Identity="BUILTIN\Administrators"; Rights="(OI)(CI)F"}
)

Write-Host "Setting NTFS permissions: HR" -ForegroundColor Yellow
Set-FolderPermissions -path "$basePath\HR" -permissions @(
    @{Identity="$domain\GRP_HR";         Rights="(OI)(CI)M"},
    @{Identity="$domain\GRP_IT";         Rights="(OI)(CI)F"},
    @{Identity="BUILTIN\Administrators"; Rights="(OI)(CI)F"}
)

Write-Host "Setting NTFS permissions: Sales" -ForegroundColor Yellow
Set-FolderPermissions -path "$basePath\Sales" -permissions @(
    @{Identity="$domain\GRP_Sales";      Rights="(OI)(CI)M"},
    @{Identity="$domain\GRP_IT";         Rights="(OI)(CI)F"},
    @{Identity="BUILTIN\Administrators"; Rights="(OI)(CI)F"}
)

Write-Host "Setting NTFS permissions: IT" -ForegroundColor Yellow
Set-FolderPermissions -path "$basePath\IT" -permissions @(
    @{Identity="$domain\GRP_IT";         Rights="(OI)(CI)F"},
    @{Identity="BUILTIN\Administrators"; Rights="(OI)(CI)F"}
)

Write-Host "=== Phase 2 Complete ===" -ForegroundColor Cyan
