# =============================================================================
# Lab 3: NTFS File Server and Access Control
# Author: Chinedu Asuzu | github.com/kingsrule50
#
# PREREQUISITES:
#   - Lab 1 (Azure Infrastructure) must be deployed
#   - Lab 2 (Active Directory) must be configured
#
# USAGE: ./run-lab3.ps1
#
# This script configures the NTFS file server in phases:
#   Phase 1 - Domain join CLIENT01 and FS01
#   Phase 2 - Configure SMB shares and NTFS permissions on FS01
#   Phase 3 - Add Domain Users to RDP group on CLIENT01
#   Phase 4 - Verify AD computers and shares
# =============================================================================

$rg = "RG-FileServerLab"

function Write-PhaseHeader {
    param([string]$Phase, [string]$Title, [string]$VM = "")
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Magenta
    Write-Host " $Phase - $Title" -ForegroundColor Magenta
    if ($VM) { Write-Host " Target VM: $VM" -ForegroundColor Magenta }
    Write-Host "============================================================" -ForegroundColor Magenta
}

function Invoke-VMScript {
    param([string]$VMName, [string]$ScriptPath)
    $fullPath = (Resolve-Path $ScriptPath).Path
    $result = az vm run-command invoke `
        --resource-group $rg `
        --name $VMName `
        --command-id RunPowerShellScript `
        --scripts "@$fullPath" `
        --output json `
        --only-show-errors | ConvertFrom-Json
    $stdout = $result.value | Where-Object { $_.code -like "*StdOut*" } | Select-Object -ExpandProperty message
    $stderr = $result.value | Where-Object { $_.code -like "*StdErr*" } | Select-Object -ExpandProperty message
    if ($stdout) { Write-Host $stdout -ForegroundColor White }
    if ($stderr) { Write-Host "STDERR: $stderr" -ForegroundColor Yellow }
}

function Wait-ForNext {
    param([string]$NextPhase)
    Write-Host ""
    Read-Host "Press ENTER to proceed to $NextPhase"
}

# =============================================================================
# PHASE 1 - Domain Join CLIENT01 and FS01
# =============================================================================
Write-PhaseHeader -Phase "PHASE 1" -Title "Domain Join CLIENT01 and FS01"

Write-Host "Joining CLIENT01 to lab.local domain..." -ForegroundColor Yellow
Invoke-VMScript -VMName "CLIENT01" -ScriptPath "./scripts/phase1-domain-join.ps1"

Write-Host ""
Write-Host "Joining FS01 to lab.local domain..." -ForegroundColor Yellow
Invoke-VMScript -VMName "FS01" -ScriptPath "./scripts/phase1-domain-join.ps1"

Write-Host ""
Write-Host "Waiting 90s for VMs to reboot and complete domain join..." -ForegroundColor Yellow
Start-Sleep -Seconds 90
Write-Host "VMs should be domain-joined and ready." -ForegroundColor Green
Wait-ForNext -NextPhase "Phase 2 - Configure Shares"

# =============================================================================
# PHASE 2 - Configure SMB Shares and NTFS Permissions on FS01
# =============================================================================
Write-PhaseHeader -Phase "PHASE 2" -Title "Configure SMB Shares and NTFS Permissions" -VM "FS01"
Invoke-VMScript -VMName "FS01" -ScriptPath "./scripts/phase2-configure-shares.ps1"
Wait-ForNext -NextPhase "Phase 3 - Configure RDP Access"

# =============================================================================
# PHASE 3 - Add Domain Users to RDP group on CLIENT01
# =============================================================================
Write-PhaseHeader -Phase "PHASE 3" -Title "Configure RDP Access on CLIENT01" -VM "CLIENT01"
Invoke-VMScript -VMName "CLIENT01" -ScriptPath "./scripts/phase3-configure-rdp.ps1"
Wait-ForNext -NextPhase "Phase 4 - Verify"

# =============================================================================
# PHASE 4 - Verify Everything
# =============================================================================
Write-PhaseHeader -Phase "PHASE 4a" -Title "Verify Domain Computers" -VM "DC01"
Invoke-VMScript -VMName "DC01" -ScriptPath "./scripts/phase4a-verify-computers.ps1"

Write-PhaseHeader -Phase "PHASE 4b" -Title "Verify SMB Shares and NTFS Permissions" -VM "FS01"
Invoke-VMScript -VMName "FS01" -ScriptPath "./scripts/phase4b-verify-shares.ps1"

# =============================================================================
# LAB 3 COMPLETE
# =============================================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " LAB 3 COMPLETE - NTFS File Server Configured!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host " RDP Connection Details:" -ForegroundColor Cyan
Write-Host "  DC01     - $(az vm show -d -g $rg -n DC01 --query publicIps -o tsv)" -ForegroundColor White
Write-Host "  FS01     - $(az vm show -d -g $rg -n FS01 --query publicIps -o tsv)" -ForegroundColor White
Write-Host "  CLIENT01 - $(az vm show -d -g $rg -n CLIENT01 --query publicIps -o tsv)" -ForegroundColor White
Write-Host ""
Write-Host " Test Access from CLIENT01:" -ForegroundColor Cyan
Write-Host "  sarah.jones --> \\FS01\Finance (Modify) \\FS01\HR (Denied)" -ForegroundColor White
Write-Host "  tom.davis   --> \\FS01\Sales (Modify)   \\FS01\Finance (Denied)" -ForegroundColor White
Write-Host "  john.smith  --> \\FS01\IT (Full Control) all shares" -ForegroundColor White
Write-Host "  Password: P@ssw0rd123!" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Green
