@echo off
echo Building Caller Tests...

set DELPHI_BIN=C:\Program Files (x86)\Embarcadero\Studio\20.0\bin
set UNIDAC=C:\Program Files (x86)\Devart\UniDAC for RAD Studio 10.3\Source
set SGCWS=C:\sgcWebSockets\Source
set DUNITX=C:\Program Files (x86)\Embarcadero\Studio\20.0\source\DUnitX

"%DELPHI_BIN%\dcc32.exe" -B -U"%UNIDAC%;%SGCWS%;%DUNITX%;.." -I"%UNIDAC%;%SGCWS%;%DUNITX%;.." CallerTests.dpr

if %ERRORLEVEL% NEQ 0 (
    echo Compilation failed!
    exit /b 1
)

echo Build successful!
echo Running tests...

Win32\Debug\CallerTests.exe

pause
