unit BarcodeTests;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  Vcl.Forms,
  Vcl.StdCtrls,
  Uni,
  MainFormU;

type
  [TestFixture]
  TBarcodeTests = class
  private
    FMainForm: TMainForm;
    FTestDatabaseConnected: Boolean;
    procedure SetupTestDatabase;
    procedure CleanupTestDatabase;
    procedure InsertTestQueue(const Barcode, QDisplay: string; Room: Integer; FStatus: string);
    function GenerateRandomBarcode: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    
    // Feature: queue-management-system, Property 9: Barcode Lookup Correctness
    // Validates: Requirements 6.1
    [Test]
    procedure TestBarcodeLookup_MultipleIterations;
    
    // Feature: queue-management-system, Property 10: Queue Status Update Completeness
    // Validates: Requirements 6.2
    [Test]
    procedure TestQueueStatusUpdate_MultipleIterations;
  end;

implementation

{ TBarcodeTests }

procedure TBarcodeTests.Setup;
begin
  Application.Initialize;
  FMainForm := TMainForm.Create(nil);
  
  // ตรวจสอบว่าเชื่อมต่อฐานข้อมูลได้หรือไม่
  FTestDatabaseConnected := False;
  try
    if not FMainForm.UniConnection1.Connected then
      FMainForm.UniConnection1.Connected := True;
    FTestDatabaseConnected := FMainForm.UniConnection1.Connected;
  except
    FTestDatabaseConnected := False;
  end;
  
  if FTestDatabaseConnected then
    SetupTestDatabase;
end;

procedure TBarcodeTests.TearDown;
begin
  if FTestDatabaseConnected then
    CleanupTestDatabase;
    
  if Assigned(FMainForm) then
    FMainForm.Free;
end;

procedure TBarcodeTests.SetupTestDatabase;
begin
  // ล้างข้อมูลทดสอบเก่า (ถ้ามี)
  CleanupTestDatabase;
end;

procedure TBarcodeTests.CleanupTestDatabase;
var
  Query: TUniQuery;
begin
  try
    Query := TUniQuery.Create(nil);
    try
      Query.Connection := FMainForm.UniConnection1;
      Query.SQL.Text := 'DELETE FROM queue_data WHERE barcodes LIKE ''TEST_%''';
      Query.Execute;
    finally
      Query.Free;
    end;
  except
    // Ignore cleanup errors
  end;
end;

procedure TBarcodeTests.InsertTestQueue(const Barcode, QDisplay: string; 
  Room: Integer; FStatus: string);
var
  Query: TUniQuery;
begin
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := FMainForm.UniConnection1;
    Query.SQL.Text := 
      'INSERT INTO queue_data (qdisplay, room, prefix, qid, fstatus, barcodes, timestamp) ' +
      'VALUES (:qdisplay, :room, :prefix, :qid, :fstatus, :barcode, NOW())';
    Query.ParamByName('qdisplay').AsString := QDisplay;
    Query.ParamByName('room').AsInteger := Room;
    Query.ParamByName('prefix').AsString := Copy(QDisplay, 1, 1);
    Query.ParamByName('qid').AsInteger := StrToIntDef(Copy(QDisplay, 2, 3), 1);
    Query.ParamByName('fstatus').AsString := FStatus;
    Query.ParamByName('barcode').AsString := Barcode;
    Query.Execute;
  finally
    Query.Free;
  end;
end;

function TBarcodeTests.GenerateRandomBarcode: string;
begin
  // สร้างบาร์โค้ดทดสอบที่ไม่ซ้ำกัน
  Result := 'TEST_' + FormatDateTime('yyyymmddhhnnsszzz', Now) + '_' + 
            IntToStr(Random(10000));
end;

procedure TBarcodeTests.TestBarcodeLookup_MultipleIterations;
var
  i: Integer;
  TestBarcode: string;
  QueueNumber: string;
  RoomID: Integer;
  LookupResult: Boolean;
begin
  // Feature: queue-management-system, Property 9: Barcode Lookup Correctness
  // For any valid barcode in the database, scanning that barcode
  // SHALL return the correct queue record with matching barcode value.
  
  if not FTestDatabaseConnected then
  begin
    Assert.Ignore('ไม่สามารถเชื่อมต่อฐานข้อมูลทดสอบได้');
    Exit;
  end;
  
  // ทดสอบ 100 iterations ด้วยบาร์โค้ดต่างๆ
  for i := 1 to 100 do
  begin
    // สร้างข้อมูลทดสอบ
    TestBarcode := GenerateRandomBarcode;
    RoomID := ((i - 1) mod 4) + 1; // สลับระหว่าง room 1-4
    
    case RoomID of
      1: QueueNumber := Format('%.4d', [i]);
      2: QueueNumber := Format('5%.3d', [i]);
      3: QueueNumber := Format('2%.3d', [i]);
      4: QueueNumber := Format('1%.3d', [i]);
    end;
    
    // เพิ่มคิวทดสอบลงฐานข้อมูล (สถานะ "2" = ยังไม่เรียก)
    InsertTestQueue(TestBarcode, QueueNumber, RoomID, '2');
    
    // ทดสอบการค้นหาบาร์โค้ด
    LookupResult := FMainForm.FindQueueByBarcode(TestBarcode);
    
    // Assert: ต้องหาบาร์โค้ดเจอ
    Assert.IsTrue(LookupResult, 
      Format('Iteration %d: ต้องหาบาร์โค้ด %s เจอในฐานข้อมูล', [i, TestBarcode]));
    
    // Assert: ข้อมูลที่ได้ต้องตรงกับที่บันทึกไว้
    Assert.IsFalse(FMainForm.UniQuery1.IsEmpty,
      Format('Iteration %d: Query result ต้องไม่ว่าง', [i]));
    
    Assert.AreEqual(QueueNumber, FMainForm.UniQuery1.FieldByName('qdisplay').AsString,
      Format('Iteration %d: หมายเลขคิวต้องตรงกับที่บันทึก', [i]));
    
    Assert.AreEqual(RoomID, FMainForm.UniQuery1.FieldByName('room').AsInteger,
      Format('Iteration %d: Room ID ต้องตรงกับที่บันทึก', [i]));
    
    Assert.AreEqual('2', FMainForm.UniQuery1.FieldByName('fstatus').AsString,
      Format('Iteration %d: สถานะต้องเป็น "2" (ยังไม่เรียก)', [i]));
  end;
  
  // ทดสอบกรณีบาร์โค้ดไม่มีในระบบ
  LookupResult := FMainForm.FindQueueByBarcode('INVALID_BARCODE_999999');
  Assert.IsFalse(LookupResult, 
    'บาร์โค้ดที่ไม่มีในระบบต้องคืนค่า False');
  
  // ทดสอบกรณีคิวถูกเรียกไปแล้ว
  TestBarcode := GenerateRandomBarcode;
  InsertTestQueue(TestBarcode, '0999', 1, '1'); // สถานะ "1" = เรียกแล้ว
  
  LookupResult := FMainForm.FindQueueByBarcode(TestBarcode);
  Assert.IsFalse(LookupResult,
    'คิวที่ถูกเรียกไปแล้ว (fstatus=1) ต้องคืนค่า False');
end;

procedure TBarcodeTests.TestQueueStatusUpdate_MultipleIterations;
var
  i: Integer;
  TestBarcode: string;
  QueueNumber: string;
  RoomID: Integer;
  ServiceCounter: Integer;
  Query: TUniQuery;
  UpdatedStatus: string;
  UpdatedCounter: string;
  TimeConfirm: TDateTime;
begin
  // Feature: queue-management-system, Property 10: Queue Status Update Completeness
  // For any queue called, the database SHALL be updated with status "เรียกแล้ว" (fstatus="1"),
  // the service counter number, and the current timestamp in time_confirm field.
  
  if not FTestDatabaseConnected then
  begin
    Assert.Ignore('ไม่สามารถเชื่อมต่อฐานข้อมูลทดสอบได้');
    Exit;
  end;
  
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := FMainForm.UniConnection1;
    
    // ทดสอบ 100 iterations
    for i := 1 to 100 do
    begin
      // สร้างข้อมูลทดสอบ
      TestBarcode := GenerateRandomBarcode;
      RoomID := ((i - 1) mod 4) + 1;
      ServiceCounter := ((i - 1) mod 9) + 1; // สลับช่องบริการ 1-9
      
      case RoomID of
        1: QueueNumber := Format('%.4d', [i]);
        2: QueueNumber := Format('5%.3d', [i]);
        3: QueueNumber := Format('2%.3d', [i]);
        4: QueueNumber := Format('1%.3d', [i]);
      end;
      
      // เพิ่มคิวทดสอบ (สถานะ "2" = ยังไม่เรียก)
      InsertTestQueue(TestBarcode, QueueNumber, RoomID, '2');
      
      // ตั้งค่าช่องบริการ
      FMainForm.cmbServiceCounter.ItemIndex := ServiceCounter;
      if Assigned(FMainForm.cmbServiceCounter.OnChange) then
        FMainForm.cmbServiceCounter.OnChange(FMainForm.cmbServiceCounter);
      
      // เรียกคิว (อัพเดทสถานะ)
      FMainForm.UpdateQueueStatus(TestBarcode);
      
      // ตรวจสอบว่าข้อมูลถูกอัพเดทถูกต้อง
      Query.Close;
      Query.SQL.Text := 
        'SELECT fstatus, counters, time_confirm ' +
        'FROM queue_data ' +
        'WHERE barcodes = :barcode';
      Query.ParamByName('barcode').AsString := TestBarcode;
      Query.Open;
      
      // Assert: ต้องมีข้อมูล
      Assert.IsFalse(Query.IsEmpty,
        Format('Iteration %d: ต้องพบข้อมูลคิวหลังอัพเดท', [i]));
      
      // Assert: สถานะต้องเป็น "1" (เรียกแล้ว)
      UpdatedStatus := Query.FieldByName('fstatus').AsString;
      Assert.AreEqual('1', UpdatedStatus,
        Format('Iteration %d: สถานะต้องเป็น "1" (เรียกแล้ว) แต่ได้ "%s"', 
        [i, UpdatedStatus]));
      
      // Assert: ช่องบริการต้องตรงกับที่ตั้งไว้
      UpdatedCounter := Query.FieldByName('counters').AsString;
      Assert.AreEqual(IntToStr(ServiceCounter), UpdatedCounter,
        Format('Iteration %d: ช่องบริการต้องเป็น %d แต่ได้ %s', 
        [i, ServiceCounter, UpdatedCounter]));
      
      // Assert: time_confirm ต้องไม่เป็น NULL และต้องเป็นเวลาปัจจุบัน (ภายใน 5 วินาที)
      Assert.IsFalse(Query.FieldByName('time_confirm').IsNull,
        Format('Iteration %d: time_confirm ต้องไม่เป็น NULL', [i]));
      
      TimeConfirm := Query.FieldByName('time_confirm').AsDateTime;
      Assert.IsTrue(Abs(Now - TimeConfirm) < (5 / SecsPerDay),
        Format('Iteration %d: time_confirm ต้องเป็นเวลาปัจจุบัน (ภายใน 5 วินาที)', [i]));
    end;
    
    // ทดสอบกรณี edge case: อัพเดทคิวเดียวกันหลายครั้ง
    TestBarcode := GenerateRandomBarcode;
    InsertTestQueue(TestBarcode, '0888', 1, '2');
    
    // เรียกครั้งแรก
    FMainForm.cmbServiceCounter.ItemIndex := 1;
    if Assigned(FMainForm.cmbServiceCounter.OnChange) then
      FMainForm.cmbServiceCounter.OnChange(FMainForm.cmbServiceCounter);
    FMainForm.UpdateQueueStatus(TestBarcode);
    
    // ตรวจสอบว่าสถานะเป็น "1"
    Query.Close;
    Query.SQL.Text := 'SELECT fstatus FROM queue_data WHERE barcodes = :barcode';
    Query.ParamByName('barcode').AsString := TestBarcode;
    Query.Open;
    Assert.AreEqual('1', Query.FieldByName('fstatus').AsString,
      'หลังเรียกครั้งแรก สถานะต้องเป็น "1"');
    
  finally
    Query.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TBarcodeTests);

end.
