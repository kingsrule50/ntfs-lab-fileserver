# =============================================================================
# Lab 3 - Phase 1: Domain Join
# Runs on: CLIENT01 and FS01
# =============================================================================
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
Write-Host "=== Phase 1: Joining Domain ===" -ForegroundColor Cyan

$adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses "10.0.1.5"
ipconfig /flushdns | Out-Null
Write-Host "  [+] DNS configured to DC01 (10.0.1.5)" -ForegroundColor Green

$retries = 0
$resolved = $false
do {
    Start-Sleep -Seconds 15
    $retries++
    $resolved = [bool](Resolve-DnsName "lab.local" -Server "10.0.1.5" -ErrorAction SilentlyContinue)
    Write-Host "  Attempt $retries -- lab.local resolved: $resolved"
} while (-not $resolved -and $retries -lt 12)

if (-not $resolved) {
    throw "lab.local did not resolve. Ensure Lab 2 (AD) is deployed first."
}

Write-Host "  [+] lab.local resolved successfully" -ForegroundColor Green

$domainCred = New-Object PSCredential(
    "azureadmin@lab.local",
    (ConvertTo-SecureString "YourStrongPassword123!" -AsPlainText -Force)
)
Add-Computer -DomainName "lab.local" -Credential $domainCred -Restart -Force
Write-Host "=== Phase 1 Complete - VM rebooting to complete domain join ===" -ForegroundColor Cyan
