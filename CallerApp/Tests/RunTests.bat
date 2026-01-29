@echo off
echo ========================================
echo Queue System - Comprehensive Test Suite
echo ========================================
echo.

echo Compiling test suite...
dcc32 -B TestRunner.dpr
if errorlevel 1 (
    echo ERROR: Compilation failed!
    pause
    exit /b 1
)

echo.
echo Running Unit Tests...
TestRunner.exe -console

echo.
echo Test execution completed.
echo Check queue_system.log for detailed performance and error logs.
echo.

pause