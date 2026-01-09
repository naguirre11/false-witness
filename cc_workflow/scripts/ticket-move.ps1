<#
.SYNOPSIS
    Moves a ticket between status folders and updates STATUS.md
.PARAMETER TicketId
    The ticket ID (e.g., FW-024)
.PARAMETER Status
    Target status: draft, ready, dev_in_progress, for_review, completed
.EXAMPLE
    .\ticket-move.ps1 FW-024 for_review
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$TicketId,

    [Parameter(Mandatory=$true)]
    [ValidateSet("draft", "ready", "dev_in_progress", "for_review", "completed")]
    [string]$Status
)

$ErrorActionPreference = "Stop"
$ticketsRoot = "$PSScriptRoot\..\..\tickets"
$statusFile = "$ticketsRoot\STATUS.md"

# Find the ticket file
$ticketFile = Get-ChildItem -Path $ticketsRoot -Recurse -Filter "*$TicketId*.md" |
    Where-Object { $_.Name -notmatch "STATUS|PRIORITIZATION" } |
    Select-Object -First 1

if (-not $ticketFile) {
    Write-Error "Ticket $TicketId not found"
    exit 1
}

$currentFolder = $ticketFile.Directory.Name
$targetFolder = Join-Path $ticketsRoot $Status

# Create target folder if needed
if (-not (Test-Path $targetFolder)) {
    New-Item -ItemType Directory -Path $targetFolder | Out-Null
}

$targetPath = Join-Path $targetFolder $ticketFile.Name

# Move the file
if ($currentFolder -ne $Status) {
    Move-Item -Path $ticketFile.FullName -Destination $targetPath -Force
    Write-Host "Moved $($ticketFile.Name): $currentFolder -> $Status"
} else {
    Write-Host "$TicketId already in $Status"
}

# Update STATUS.md
if (Test-Path $statusFile) {
    $content = Get-Content $statusFile -Raw

    # Extract ticket name without extension for matching (e.g., FW-024-protection-items)
    $ticketName = [System.IO.Path]::GetFileNameWithoutExtension($ticketFile.Name)

    # Update the status column (3-column format: Ticket | Title | Status)
    $pattern = "(?m)^\|\s*$ticketName\s*\|([^|]*)\|[^|]*\|"
    $replacement = "| $ticketName |`$1| $Status |"

    if ($content -match $pattern) {
        $content = $content -replace $pattern, $replacement
        Set-Content -Path $statusFile -Value $content.TrimEnd() -NoNewline
        Write-Host "Updated STATUS.md"
    } else {
        Write-Host "Warning: $ticketName not found in STATUS.md"
    }
}

Write-Host "Done."
