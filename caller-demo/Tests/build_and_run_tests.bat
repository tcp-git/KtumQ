@echo off
echo Building Caller Tests...

REM Set the path to Delphi compiler (adjust if needed)
set DELPHI_BDS=C:\Program Files (x86)\Embarcadero\Studio\20.0
set DCC32="%DELPHI_BDS%\bin\dcc32.exe"

REM Check if compiler exists
if not exist %DCC32% (
    echo ERROR: Delphi compiler not found at %DCC32%
    echo Please adjust the DELPHI_BDS path in this script
    pause
    exit /b 1
)

REM Build the test project
echo Compiling CallerTests.dpr...
%DCC32% -B CallerTests.dpr

if errorlevel 1 (
    echo ERROR: Compilation failed
    pause
    exit /b 1
)

echo.
echo Build successful!
echo.
echo Running tests...
echo.

REM Run the tests
Win32\Debug\CallerTests.exe

echo.
echo Tests completed.
pause
