# =============================================================================
# Lab 3 - Phase 3: Configure RDP Access on CLIENT01
# Runs on: CLIENT01
# Purpose: Add Domain Users to Remote Desktop Users group
# =============================================================================
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
Write-Host "=== Phase 3: Configuring RDP Access ===" -ForegroundColor Cyan

$rdpGroup   = "Remote Desktop Users"
$domainUsers = "LAB\Domain Users"

$existing = Get-LocalGroupMember -Group $rdpGroup -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -eq $domainUsers }

if ($existing) {
    Write-Host "  [~] $domainUsers already in $rdpGroup" -ForegroundColor Yellow
} else {
    Add-LocalGroupMember -Group $rdpGroup -Member $domainUsers
    Write-Host "  [+] Added $domainUsers to $rdpGroup" -ForegroundColor Green
}

Write-Host ""
Write-Host "  Current RDP Group Members:" -ForegroundColor Yellow
Get-LocalGroupMember -Group $rdpGroup | Select-Object Name, ObjectClass | Format-Table -AutoSize

Write-Host "=== Phase 3 Complete ===" -ForegroundColor Cyan
