# =============================================================================
# Lab 3 - Phase 4a: Verify Domain Computers
# Runs on: DC01
# =============================================================================
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
Import-Module ActiveDirectory
Write-Host "=== Phase 4a: Verifying Domain Computers ===" -ForegroundColor Cyan

$pass = $true
$expectedComputers = @("DC01", "CLIENT01", "FS01")

foreach ($computer in $expectedComputers) {
    $exists = Get-ADComputer -Filter "Name -eq '$computer'" -ErrorAction SilentlyContinue
    if ($exists) {
        Write-Host "  [PASS] $computer is domain-joined" -ForegroundColor Green
        Write-Host "         $($exists.DistinguishedName)" -ForegroundColor Gray
    } else {
        Write-Host "  [FAIL] $computer not found in AD" -ForegroundColor Red
        $pass = $false
    }
}

Write-Host ""
if ($pass) { Write-Host "=== Phase 4a PASSED ===" -ForegroundColor Green }
else { Write-Host "=== Phase 4a FAILED ===" -ForegroundColor Red }
