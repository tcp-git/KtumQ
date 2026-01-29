@echo off
REM Build script สำหรับ Caller Tests พร้อม library paths

echo ========================================
echo Building Caller Tests with Library Paths
echo ========================================
echo.

REM ตั้งค่า library paths (ปรับตามเครื่องของคุณ)
set UNIDAC_PATH=C:\Program Files (x86)\Devart\UniDAC for RAD Studio 10.3\Source
set SGCWS_PATH=C:\sgcWebSockets\Source
set DUNITX_PATH=C:\Program Files (x86)\Embarcadero\Studio\20.0\source\DUnitX

REM หา Delphi compiler
set DELPHI_PATH=
if exist "C:\Program Files (x86)\Embarcadero\Studio\20.0\bin\dcc32.exe" (
    set DELPHI_PATH=C:\Program Files (x86)\Embarcadero\Studio\20.0\bin
)

if "%DELPHI_PATH%"=="" (
    echo ERROR: Delphi compiler not found!
    echo Please check that Delphi 10.3 is installed
    pause
    exit /b 1
)

echo Delphi Compiler: %DELPHI_PATH%\dcc32.exe
echo.

REM ตรวจสอบว่า library paths มีอยู่จริง
echo Checking library paths...

if not exist "%UNIDAC_PATH%" (
    echo WARNING: UniDAC path not found: %UNIDAC_PATH%
    echo Please adjust UNIDAC_PATH in this file
)

if not exist "%SGCWS_PATH%" (
    echo WARNING: sgcWebSocket path not found: %SGCWS_PATH%
    echo Please adjust SGCWS_PATH in this file
)

if not exist "%DUNITX_PATH%" (
    echo WARNING: DUnitX path not found: %DUNITX_PATH%
    echo Please adjust DUNITX_PATH in this file
)

echo.
echo Compiling CallerTests.dpr...
echo.

REM Compile โดยใช้ library paths
"%DELPHI_PATH%\dcc32.exe" -B -U"%UNIDAC_PATH%;%SGCWS_PATH%;%DUNITX_PATH%;.." -I"%UNIDAC_PATH%;%SGCWS_PATH%;%DUNITX_PATH%;.." CallerTests.dpr

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================
    echo ERROR: Compilation failed!
    echo ========================================
    echo.
    echo Please check:
    echo 1. Library paths are correct
    echo 2. UniDAC, sgcWebSocket, DUnitX are installed
    echo 3. Source code has no syntax errors
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Build successful!
echo ========================================
echo.
echo Running tests...
echo.

REM รัน tests
Win32\Debug\CallerTests.exe

echo.
echo ========================================
echo Tests completed
echo ========================================
pause
