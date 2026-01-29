@echo off
echo Building Caller Installer...
echo.

REM Change to project root directory
cd /d "%~dp0\.."

REM Check if NSIS is installed
where makensis >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: NSIS (Nullsoft Scriptable Install System) is not installed or not in PATH
    echo Please download and install NSIS from: https://nsis.sourceforge.io/Download
    echo.
    pause
    exit /b 1
)

REM Check if the executable exists
if not exist "Win32\Debug\Caller.exe" (
    echo ERROR: Caller.exe not found in Win32\Debug\
    echo Please build the Delphi project first
    echo.
    pause
    exit /b 1
)

REM Create the installer
echo Compiling NSIS script...
makensis setup\setup.nsi

if %ERRORLEVEL% EQU 0 (
    echo.
    echo SUCCESS: Installer created successfully!
    echo Output file: CallerSetup.exe
    echo.
    
    REM Show file size
    for %%A in (CallerSetup.exe) do echo Installer size: %%~zA bytes
    echo.
    
    REM Ask if user wants to test the installer
    set /p test="Do you want to test the installer now? (y/n): "
    if /i "%test%"=="y" (
        echo Starting installer...
        start CallerSetup.exe
    )
) else (
    echo.
    echo ERROR: Failed to create installer
    echo Check the output above for errors
)

echo.
pause