# PowerShell script สำหรับ compile Caller Tests

Write-Host "========================================"
Write-Host "Building Caller Tests with Library Paths"
Write-Host "========================================"
Write-Host ""

# ตั้งค่า library paths
$UNIDAC_PATH = "C:\Program Files (x86)\Devart\UniDAC for RAD Studio 10.3\Source"
$SGCWS_PATH = "C:\sgcWebSockets\Source"
$DUNITX_PATH = "C:\Program Files (x86)\Embarcadero\Studio\20.0\source\DUnitX"
$DELPHI_PATH = "C:\Program Files (x86)\Embarcadero\Studio\20.0\bin"

# ตรวจสอบ Delphi compiler
$DCC32 = Join-Path $DELPHI_PATH "dcc32.exe"
if (-not (Test-Path $DCC32)) {
    Write-Host "ERROR: Delphi compiler not found at $DCC32" -ForegroundColor Red
    Write-Host "Please check that Delphi 10.3 is installed"
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Delphi Compiler: $DCC32"
Write-Host ""

# ตรวจสอบ library paths
Write-Host "Checking library paths..."
if (-not (Test-Path $UNIDAC_PATH)) {
    Write-Host "WARNING: UniDAC path not found: $UNIDAC_PATH" -ForegroundColor Yellow
}
if (-not (Test-Path $SGCWS_PATH)) {
    Write-Host "WARNING: sgcWebSocket path not found: $SGCWS_PATH" -ForegroundColor Yellow
}
if (-not (Test-Path $DUNITX_PATH)) {
    Write-Host "WARNING: DUnitX path not found: $DUNITX_PATH" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Compiling CallerTests.dpr..."
Write-Host ""

# สร้าง library path string
$LibPaths = "$UNIDAC_PATH;$SGCWS_PATH;$DUNITX_PATH;.."

# Compile
& $DCC32 -B "-U$LibPaths" "-I$LibPaths" CallerTests.dpr

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "ERROR: Compilation failed!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please check:"
    Write-Host "1. Library paths are correct"
    Write-Host "2. UniDAC, sgcWebSocket, DUnitX are installed"
    Write-Host "3. Source code has no syntax errors"
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Build successful!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Running tests..."
Write-Host ""

# รัน tests
& ".\Win32\Debug\CallerTests.exe"

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Tests completed" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Read-Host "Press Enter to exit"
