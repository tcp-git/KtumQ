unit ServiceCounterTests;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  Vcl.Forms,
  Vcl.StdCtrls,
  MainFormU;

type
  [TestFixture]
  TServiceCounterTests = class
  private
    FMainForm: TMainForm;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    
    // Feature: queue-management-system, Property 12: Service Counter Persistence
    // Validates: Requirements 7.2, 7.3
    [Test]
    procedure TestServiceCounterPersistence_MultipleIterations;
  end;

implementation

{ TServiceCounterTests }

procedure TServiceCounterTests.Setup;
begin
  // Create the main form for testing
  Application.Initialize;
  FMainForm := TMainForm.Create(nil);
end;

procedure TServiceCounterTests.TearDown;
begin
  if Assigned(FMainForm) then
    FMainForm.Free;
end;

procedure TServiceCounterTests.TestServiceCounterPersistence_MultipleIterations;
var
  i: Integer;
  SelectedCounter: Integer;
  ExpectedCounter: Integer;
begin
  // Feature: queue-management-system, Property 12: Service Counter Persistence
  // For any service counter number selected in Caller, that counter number
  // SHALL be used in all subsequent queue calls until changed.
  
  // Test 100 iterations with different counter selections
  for i := 1 to 100 do
  begin
    // Select a random counter between 1 and 9
    ExpectedCounter := (i mod 9) + 1;
    
    // Set the ComboBox selection (ItemIndex 0 is the prompt, so add 1)
    FMainForm.cmbServiceCounter.ItemIndex := ExpectedCounter;
    
    // Trigger the change event manually
    if Assigned(FMainForm.cmbServiceCounter.OnChange) then
      FMainForm.cmbServiceCounter.OnChange(FMainForm.cmbServiceCounter);
    
    // Assert: The selected counter should be stored in memory
    SelectedCounter := FMainForm.SelectedCounter;
    Assert.AreEqual(ExpectedCounter, SelectedCounter,
      Format('Iteration %d: Selected counter should be %d but got %d', 
      [i, ExpectedCounter, SelectedCounter]));
    
    // Assert: The display label should show the correct counter
    Assert.IsTrue(FMainForm.lblSelectedCounter.Caption.Contains(IntToStr(ExpectedCounter)),
      Format('Iteration %d: Display label should contain counter number %d', 
      [i, ExpectedCounter]));
    
    // Verify persistence: The counter should remain the same until explicitly changed
    // Read the property multiple times to ensure it doesn't change
    Assert.AreEqual(ExpectedCounter, FMainForm.SelectedCounter,
      Format('Iteration %d: Counter should persist on first read', [i]));
    Assert.AreEqual(ExpectedCounter, FMainForm.SelectedCounter,
      Format('Iteration %d: Counter should persist on second read', [i]));
    Assert.AreEqual(ExpectedCounter, FMainForm.SelectedCounter,
      Format('Iteration %d: Counter should persist on third read', [i]));
  end;
  
  // Test edge case: Setting to "no selection" (index 0)
  FMainForm.cmbServiceCounter.ItemIndex := 0;
  if Assigned(FMainForm.cmbServiceCounter.OnChange) then
    FMainForm.cmbServiceCounter.OnChange(FMainForm.cmbServiceCounter);
  
  // Assert: When no valid counter is selected, SelectedCounter should be 0
  Assert.AreEqual(0, FMainForm.SelectedCounter,
    'When no counter is selected, SelectedCounter should be 0');
  
  // Assert: Display should indicate no selection
  Assert.IsTrue(FMainForm.lblSelectedCounter.Caption.Contains('ยังไม่ได้เลือก'),
    'Display should indicate no counter is selected');
  
  // Test persistence after setting back to a valid counter
  FMainForm.cmbServiceCounter.ItemIndex := 5; // Counter 5
  if Assigned(FMainForm.cmbServiceCounter.OnChange) then
    FMainForm.cmbServiceCounter.OnChange(FMainForm.cmbServiceCounter);
  
  Assert.AreEqual(5, FMainForm.SelectedCounter,
    'After selecting counter 5, it should be stored');
  
  // Verify it persists across multiple reads
  for i := 1 to 10 do
  begin
    Assert.AreEqual(5, FMainForm.SelectedCounter,
      Format('Counter 5 should persist on read %d', [i]));
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TServiceCounterTests);

end.
