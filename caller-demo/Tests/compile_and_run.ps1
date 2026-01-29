# PowerShell script สำหรับ compile และรัน Caller Tests

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Building Caller Tests" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ตั้งค่า paths
$DelphiBin = "C:\Program Files (x86)\Embarcadero\Studio\20.0\bin"
$UniDAC = "C:\Program Files (x86)\Devart\UniDAC for RAD Studio 10.3\Source"
$SGCWS = "C:\sgcWebSockets\Source"
$DUnitX = "C:\Program Files (x86)\Embarcadero\Studio\20.0\source\DUnitX"
$ParentDir = ".."

# ตรวจสอบว่า compiler มีอยู่
$CompilerPath = Join-Path $DelphiBin "dcc32.exe"
if (-not (Test-Path $CompilerPath)) {
    Write-Host "ERROR: Delphi compiler not found at $CompilerPath" -ForegroundColor Red
    Write-Host "Please adjust the DelphiBin path in this script" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Delphi Compiler: $CompilerPath" -ForegroundColor Green
Write-Host ""

# ตรวจสอบ library paths
Write-Host "Checking library paths..." -ForegroundColor Yellow

if (-not (Test-Path $UniDAC)) {
    Write-Host "WARNING: UniDAC path not found: $UniDAC" -ForegroundColor Yellow
}

if (-not (Test-Path $SGCWS)) {
    Write-Host "WARNING: sgcWebSocket path not found: $SGCWS" -ForegroundColor Yellow
}

if (-not (Test-Path $DUnitX)) {
    Write-Host "WARNING: DUnitX path not found: $DUnitX" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Compiling CallerTests.dpr..." -ForegroundColor Cyan
Write-Host ""

# สร้าง command line arguments
$UnitPaths = "$UniDAC;$SGCWS;$DUnitX;$ParentDir"
$IncludePaths = "$UniDAC;$SGCWS;$DUnitX;$ParentDir"

# Compile
& $CompilerPath -B "-U$UnitPaths" "-I$IncludePaths" "CallerTests.dpr"

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "ERROR: Compilation failed!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please check:" -ForegroundColor Yellow
    Write-Host "1. Library paths are correct" -ForegroundColor Yellow
    Write-Host "2. UniDAC, sgcWebSocket, DUnitX are installed" -ForegroundColor Yellow
    Write-Host "3. Source code has no syntax errors" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Build successful!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Running tests..." -ForegroundColor Cyan
Write-Host ""

# รัน tests
$TestExe = "Win32\Debug\CallerTests.exe"
if (Test-Path $TestExe) {
    & $TestExe
} else {
    Write-Host "ERROR: Test executable not found at $TestExe" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Tests completed" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Read-Host "Press Enter to exit"
