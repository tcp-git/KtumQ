# Instructions for Running Caller Tests

## Property Test Created

**Property 12: Service Counter Persistence** has been implemented in `ServiceCounterTests.pas`.

This test validates Requirements 7.2 and 7.3 by verifying that:
- The selected service counter number is stored in memory
- The counter persists across multiple reads
- The counter remains unchanged until explicitly modified
- The UI display correctly reflects the selected counter

## Running the Tests

### Prerequisites
1. Delphi 10.3 Rio or later installed
2. DUnitX framework available
3. All required components (UniDAC, sgcWebSocket, VCL)

### Steps to Run

#### Option 1: Using Delphi IDE (Recommended)
1. Open `caller_new/Tests/CallerTests.dproj` in Delphi IDE
2. Ensure all library paths are configured:
   - UniDAC library path
   - sgcWebSocket library path
   - DUnitX library path
3. Build the project (Project → Build CallerTests)
4. Run the tests (Run → Run Without Debugging or Ctrl+Shift+F9)

#### Option 2: Command Line
```batch
cd caller_new\Tests
build_and_run_tests.bat
```

Note: You may need to adjust the `DELPHI_BDS` path in `build_and_run_tests.bat` to match your Delphi installation.

## Test Details

The test runs 100 iterations with different counter selections (1-9) and verifies:
1. Counter value is correctly stored when ComboBox selection changes
2. Counter value persists across multiple property reads
3. Display label shows the correct counter number
4. Edge case: "no selection" state (index 0) sets counter to 0
5. Counter can be changed and the new value persists

## Expected Output

When all tests pass, you should see:
```
[PASS] TestServiceCounterPersistence_MultipleIterations
Tests Run: 1, Passed: 1, Failed: 0
```

## Troubleshooting

If compilation fails:
1. Verify all component libraries are installed
2. Check library paths in Project Options
3. Ensure DUnitX is properly installed
4. Verify the parent form (MainFormU.pas) compiles successfully

If tests fail:
1. Check that the ComboBox is properly initialized
2. Verify the OnChange event is wired correctly
3. Ensure the SelectedCounter property is accessible
4. Check that the display label exists and is updated
