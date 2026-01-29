# PowerShell script to build Caller installer
Write-Host "Building Caller Installer..." -ForegroundColor Green
Write-Host ""

# Change to project root directory
Set-Location (Split-Path $PSScriptRoot -Parent)

# Check if NSIS is installed
$nsisPath = Get-Command makensis -ErrorAction SilentlyContinue
if (-not $nsisPath) {
    Write-Host "ERROR: NSIS (Nullsoft Scriptable Install System) is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please download and install NSIS from: https://nsis.sourceforge.io/Download" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if the executable exists
if (-not (Test-Path "Win32\Debug\Caller.exe")) {
    Write-Host "ERROR: Caller.exe not found in Win32\Debug\" -ForegroundColor Red
    Write-Host "Please build the Delphi project first" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Create the installer
Write-Host "Compiling NSIS script..." -ForegroundColor Cyan
$result = & makensis setup\setup.nsi

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "SUCCESS: Installer created successfully!" -ForegroundColor Green
    Write-Host "Output file: CallerSetup.exe" -ForegroundColor White
    Write-Host ""
    
    # Show file size
    $fileSize = (Get-Item "CallerSetup.exe").Length
    Write-Host "Installer size: $fileSize bytes" -ForegroundColor White
    Write-Host ""
    
    # Ask if user wants to test the installer
    $test = Read-Host "Do you want to test the installer now? (y/n)"
    if ($test -eq "y" -or $test -eq "Y") {
        Write-Host "Starting installer..." -ForegroundColor Cyan
        Start-Process "CallerSetup.exe"
    }
} else {
    Write-Host ""
    Write-Host "ERROR: Failed to create installer" -ForegroundColor Red
    Write-Host "Check the output above for errors" -ForegroundColor Yellow
}

Write-Host ""
Read-Host "Press Enter to exit"