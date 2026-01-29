# Caller Application Tests

This directory contains property-based tests for the Caller application using DUnitX framework.

## Test Coverage

### Property 12: Service Counter Persistence
**File:** `ServiceCounterTests.pas`
**Validates:** Requirements 7.2, 7.3

Tests that the selected service counter number persists in memory and is used consistently until explicitly changed.

## Running Tests

### Option 1: Using Batch File (Windows)
```batch
cd Tests
build_and_run_tests.bat
```

### Option 2: Using Delphi IDE
1. Open `CallerTests.dproj` in Delphi IDE
2. Build the project (Shift+F9)
3. Run without debugging (Ctrl+Shift+F9)

### Option 3: Manual Compilation
```batch
dcc32 -B CallerTests.dpr
Win32\Debug\CallerTests.exe
```

## Test Structure

Each property test runs 100+ iterations to verify the property holds across various inputs and scenarios.

## Requirements

- Delphi 10.3 Rio or later
- DUnitX framework
- VCL components
- UniDAC components (for database tests)
- sgcWebSocket components

## Notes

- Tests create a test form instance to verify UI behavior
- Service counter selection is tested with values 1-9
- Edge cases include "no selection" state (index 0)
- Persistence is verified across multiple reads
