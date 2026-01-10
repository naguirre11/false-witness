<#
.SYNOPSIS
    Run GUT tests with different modes for tiered testing strategy.

.DESCRIPTION
    This script supports the tiered testing strategy:
    - smoke: Quick sanity checks (~20 critical tests) - run before commits
    - unit: Fast unit tests only - run during development
    - integration: Integration tests only - run for specific system changes
    - full: Complete test suite - run in CI/before PR
    - file: Run a specific test file - run during development

.PARAMETER Mode
    Test mode: smoke, unit, integration, full, or file

.PARAMETER File
    When Mode is 'file', specifies the test file to run (e.g., test_audio_manager.gd)

.PARAMETER Dir
    When Mode is 'file', optionally specify the directory (unit or integration).
    If not specified, searches both directories.

.EXAMPLE
    .\run-tests.ps1 -Mode smoke
    Run smoke tests before committing

.EXAMPLE
    .\run-tests.ps1 -Mode file -File test_audio_manager.gd
    Run a specific test file

.EXAMPLE
    .\run-tests.ps1 -Mode full
    Run the complete test suite
#>

param(
    [ValidateSet("smoke", "unit", "integration", "full", "file")]
    [string]$Mode = "smoke",

    [string]$File = "",

    [ValidateSet("", "unit", "integration")]
    [string]$Dir = ""
)

$ErrorActionPreference = "Stop"

# Check for GODOT environment variable
if (-not $env:GODOT) {
    Write-Error "GODOT environment variable not set. Set it to your Godot console executable path."
    exit 1
}

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

function Run-GutTests {
    param(
        [string]$ConfigFile = "",
        [string]$TestFile = "",
        [string]$TestDir = ""
    )

    $gutArgs = @("--headless", "-s", "addons/gut/gut_cmdln.gd")

    if ($ConfigFile) {
        $gutArgs += "-gconfig=$ConfigFile"
    }

    if ($TestFile) {
        $gutArgs += "-gtest=$TestFile"
    }

    if ($TestDir) {
        $gutArgs += "-gdir=$TestDir"
    }

    $gutArgs += "-gexit"

    Push-Location $ProjectRoot
    try {
        Write-Host "Running: $env:GODOT $($gutArgs -join ' ')" -ForegroundColor Cyan
        & $env:GODOT @gutArgs
        $exitCode = $LASTEXITCODE
    }
    finally {
        Pop-Location
    }

    return $exitCode
}

switch ($Mode) {
    "smoke" {
        Write-Host "`n=== SMOKE TESTS ===" -ForegroundColor Green
        Write-Host "Running critical sanity checks..." -ForegroundColor Gray
        $exitCode = Run-GutTests -ConfigFile ".gutconfig.smoke.json"
    }

    "unit" {
        Write-Host "`n=== UNIT TESTS ===" -ForegroundColor Green
        Write-Host "Running fast unit tests..." -ForegroundColor Gray
        $exitCode = Run-GutTests -ConfigFile ".gutconfig.unit.json"
    }

    "integration" {
        Write-Host "`n=== INTEGRATION TESTS ===" -ForegroundColor Green
        Write-Host "Running integration tests..." -ForegroundColor Gray
        $exitCode = Run-GutTests -ConfigFile ".gutconfig.integration.json"
    }

    "full" {
        Write-Host "`n=== FULL TEST SUITE ===" -ForegroundColor Green
        Write-Host "Running all tests..." -ForegroundColor Gray
        $exitCode = Run-GutTests -ConfigFile ".gutconfig.json"

        # Record successful full test run
        if ($exitCode -eq 0) {
            $trackingFile = Join-Path $ProjectRoot ".last_full_test.json"
            Push-Location $ProjectRoot
            $commitHash = git rev-parse HEAD 2>$null
            $commitShort = git rev-parse --short HEAD 2>$null
            Pop-Location

            $tracking = @{
                commit = $commitHash
                commit_short = $commitShort
                date = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                date_iso = (Get-Date).ToString("o")
            }
            $tracking | ConvertTo-Json | Set-Content $trackingFile -Encoding UTF8
            Write-Host "Recorded full test pass at commit $commitShort" -ForegroundColor Cyan
        }
    }

    "file" {
        if (-not $File) {
            Write-Error "File mode requires -File parameter"
            exit 1
        }

        # Determine the directory
        $testDir = ""
        if ($Dir) {
            $testDir = "res://tests/$Dir/"
        }
        else {
            # Search for the file
            $unitPath = Join-Path $ProjectRoot "tests/unit/$File"
            $integrationPath = Join-Path $ProjectRoot "tests/integration/$File"
            $rootPath = Join-Path $ProjectRoot "tests/$File"

            if (Test-Path $unitPath) {
                $testDir = "res://tests/unit/"
            }
            elseif (Test-Path $integrationPath) {
                $testDir = "res://tests/integration/"
            }
            elseif (Test-Path $rootPath) {
                $testDir = "res://tests/"
            }
            else {
                Write-Error "Test file not found: $File"
                exit 1
            }
        }

        Write-Host "`n=== SINGLE FILE TEST ===" -ForegroundColor Green
        Write-Host "Running: $File" -ForegroundColor Gray
        $exitCode = Run-GutTests -TestFile $File -TestDir $testDir
    }
}

if ($exitCode -eq 0) {
    Write-Host "`nTests PASSED" -ForegroundColor Green
}
else {
    Write-Host "`nTests FAILED (exit code: $exitCode)" -ForegroundColor Red
}

exit $exitCode
