<#
.SYNOPSIS
    Run the autonomous task orchestrator.

.DESCRIPTION
    Wrapper script for the Python-based task orchestrator.
    Uses a two-Claude architecture: Orchestrator Claude directs Agent Claude.

.PARAMETER Ticket
    Specific ticket ID to work on (e.g., FW-061)

.PARAMETER MaxIterations
    Maximum number of iterations (default: 20)

.PARAMETER DryRun
    Show plan without executing

.PARAMETER Verbose
    Enable verbose output

.EXAMPLE
    ./orchestrate.ps1
    # Runs orchestrator on next ticket from queue

.EXAMPLE
    ./orchestrate.ps1 -Ticket FW-061
    # Works on specific ticket

.EXAMPLE
    ./orchestrate.ps1 -DryRun
    # Shows current state without executing
#>

param(
    [Parameter(Position = 0)]
    [string]$Ticket,

    [Parameter()]
    [Alias("n")]
    [int]$MaxIterations = 20,

    [Parameter()]
    [switch]$DryRun,

    [Parameter()]
    [Alias("v")]
    [switch]$VerboseOutput
)

# Get project root (two levels up from this script)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)

# Build command arguments
$args = @()

if ($Ticket) {
    $args += "--ticket"
    $args += $Ticket
}

if ($MaxIterations -ne 20) {
    $args += "--max-iterations"
    $args += $MaxIterations
}

if ($DryRun) {
    $args += "--dry-run"
}

if ($VerboseOutput) {
    $args += "--verbose"
}

# Run the orchestrator
Push-Location $ProjectRoot
try {
    python -m cc_workflow.orchestrator.main @args
    $exitCode = $LASTEXITCODE
}
finally {
    Pop-Location
}

exit $exitCode
