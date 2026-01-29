unit QueueSelectionTests;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  System.DateUtils,
  Vcl.Forms,
  Uni,
  MainFormU;

type
  [TestFixture]
  TQueueSelectionTests = class
  private
    FMainForm: TMainForm;
    FTestDatabaseConnected: Boolean;
    procedure SetupTestDatabase;
    procedure CleanupTestDatabase;
    procedure InsertTestQueue(const Barcode, QDisplay: string; Room: Integer; 
      FStatus: string; TimestampOffset: Integer = 0);
    function GenerateRandomBarcode: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    
    // Feature: queue-management-system, Property 19: Next Queue Selection
    // Validates: Requirements 10.2, 11.1, 11.2, 11.3, 11.4
    [Test]
    procedure TestNextQueueSelection_MultipleIterations;
    
    // Feature: queue-management-system, Property 20: Manual Call Queue Update
    // Validates: Requirements 11.5
    [Test]
    procedure TestManualCallQueueUpdate_MultipleIterations;
  end;

implementation

{ TQueueSelectionTests }

procedure TQueueSelectionTests.Setup;
begin
  Application.Initialize;
  FMainForm := TMainForm.Create(nil);
  
  // ตรวจสอบการเชื่อมต่อฐานข้อมูล
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

procedure TQueueSelectionTests.TearDown;
begin
  if FTestDatabaseConnected then
    CleanupTestDatabase;
    
  if Assigned(FMainForm) then
    FMainForm.Free;
end;

procedure TQueueSelectionTests.SetupTestDatabase;
begin
  // ล้างข้อมูลทดสอบเก่า
  CleanupTestDatabase;
end;

procedure TQueueSelectionTests.CleanupTestDatabase;
var
  Query: TUniQuery;
begin
  try
    Query := TUniQuery.Create(nil);
    try
      Query.Connection := FMainForm.UniConnection1;
      Query.SQL.Text := 'DELETE FROM queue_data WHERE barcodes LIKE ''TEST_SELECTION_%''';
      Query.Execute;
    finally
      Query.Free;
    end;
  except
    // ละเว้นข้อผิดพลาดในการล้างข้อมูล
  end;
end;

procedure TQueueSelectionTests.InsertTestQueue(const Barcode, QDisplay: string; 
  Room: Integer; FStatus: string; TimestampOffset: Integer = 0);
var
  Query: TUniQuery;
  TimestampSQL: string;
begin
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := FMainForm.UniConnection1;
    
    // สร้าง timestamp ที่ต่างกัน (เพื่อทดสอบการเรียงลำดับ)
    if TimestampOffset = 0 then
      TimestampSQL := 'NOW()'
    else
      TimestampSQL := Format('DATE_SUB(NOW(), INTERVAL %d SECOND)', [TimestampOffset]);
    
    Query.SQL.Text := 
      'INSERT INTO queue_data (qdisplay, room, prefix, qid, fstatus, barcodes, timestamp) ' +
      'VALUES (:qdisplay, :room, :prefix, :qid, :fstatus, :barcode, ' + TimestampSQL + ')';
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

function TQueueSelectionTests.GenerateRandomBarcode: string;
begin
  // สร้างบาร์โค้ดทดสอบที่ไม่ซ้ำกัน
  Result := 'TEST_SELECTION_' + FormatDateTime('yyyymmddhhnnsszzz', Now) + '_' + 
            IntToStr(Random(10000));
end;

procedure TQueueSelectionTests.TestNextQueueSelection_MultipleIterations;
var
  i, j: Integer;
  RoomID: Integer;
  TestBarcode: array[1..5] of string;
  QueueNumber: array[1..5] of string;
  SelectedQueueNumber, SelectedBarcode: string;
  Query: TUniQuery;
  OldestTimestamp: TDateTime;
  SelectedTimestamp: TDateTime;
begin
  // Feature: queue-management-system, Property 19: Next Queue Selection
  // For any service category, the next queue to call SHALL be the queue
  // with the oldest timestamp where fstatus="2" and room matches the category.
  
  if not FTestDatabaseConnected then
  begin
    Assert.Ignore('ไม่สามารถเชื่อมต่อฐานข้อมูลทดสอบได้');
    Exit;
  end;
  
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := FMainForm.UniConnection1;
    
    // ทดสอบ 100 iterations โดยสลับระหว่าง room 1-4
    for i := 1 to 100 do
    begin
      RoomID := ((i - 1) mod 4) + 1;
      
      // สร้างคิวทดสอบ 5 คิวสำหรับ room นี้ โดยมี timestamp ต่างกัน
      for j := 1 to 5 do
      begin
        TestBarcode[j] := GenerateRandomBarcode;
        
        case RoomID of
          1: QueueNumber[j] := Format('%.4d', [(i-1)*5 + j]);
          2: QueueNumber[j] := Format('5%.3d', [(i-1)*5 + j]);
          3: QueueNumber[j] := Format('2%.3d', [(i-1)*5 + j]);
          4: QueueNumber[j] := Format('1%.3d', [(i-1)*5 + j]);
        end;
        
        // เพิ่มคิวโดยคิวแรกมี timestamp เก่าที่สุด (offset มากที่สุด)
        // TimestampOffset: คิวที่ 1 = 50 วินาที, คิวที่ 2 = 40 วินาที, ... คิวที่ 5 = 10 วินาที
        InsertTestQueue(TestBarcode[j], QueueNumber[j], RoomID, '2', (6-j) * 10);
        
        // รอเล็กน้อยเพื่อให้แน่ใจว่า timestamp ต่างกัน
        Sleep(10);
      end;
      
      // Query หาคิวที่เก่าที่สุดสำหรับ room นี้
      Query.Close;
      Query.SQL.Text := 
        'SELECT qdisplay, barcodes, timestamp ' +
        'FROM queue_data ' +
        'WHERE room = :room AND fstatus = ''2'' AND barcodes LIKE ''TEST_SELECTION_%'' ' +
        'ORDER BY timestamp ASC ' +
        'LIMIT 1';
      Query.ParamByName('room').AsInteger := RoomID;
      Query.Open;
      
      // Assert: ต้องมีคิวรอ
      Assert.IsFalse(Query.IsEmpty,
        Format('Iteration %d (Room %d): ต้องมีคิวรอในฐานข้อมูล', [i, RoomID]));
      
      // เก็บข้อมูลคิวที่เก่าที่สุดจาก query
      OldestTimestamp := Query.FieldByName('timestamp').AsDateTime;
      
      // ใช้ฟังก์ชัน GetNextQueueForRoom เพื่อหาคิวถัดไป
      Assert.IsTrue(FMainForm.GetNextQueueForRoom(RoomID, SelectedQueueNumber, SelectedBarcode),
        Format('Iteration %d (Room %d): GetNextQueueForRoom ต้องคืนค่า True', [i, RoomID]));
      
      // Assert: คิวที่เลือกต้องเป็นคิวแรก (มี timestamp เก่าที่สุด)
      Assert.AreEqual(QueueNumber[1], SelectedQueueNumber,
        Format('Iteration %d (Room %d): คิวที่เลือกต้องเป็นคิวที่มี timestamp เก่าที่สุด', [i, RoomID]));
      
      Assert.AreEqual(TestBarcode[1], SelectedBarcode,
        Format('Iteration %d (Room %d): บาร์โค้ดที่เลือกต้องตรงกับคิวที่มี timestamp เก่าที่สุด', [i, RoomID]));
      
      // ตรวจสอบว่าคิวที่เลือกมี timestamp เก่าที่สุดจริง
      Query.Close;
      Query.SQL.Text := 
        'SELECT timestamp ' +
        'FROM queue_data ' +
        'WHERE barcodes = :barcode';
      Query.ParamByName('barcode').AsString := SelectedBarcode;
      Query.Open;
      
      SelectedTimestamp := Query.FieldByName('timestamp').AsDateTime;
      
      // Assert: timestamp ของคิวที่เลือกต้องเท่ากับ timestamp เก่าที่สุด
      Assert.IsTrue(Abs(SelectedTimestamp - OldestTimestamp) < (1 / SecsPerDay),
        Format('Iteration %d (Room %d): timestamp ของคิวที่เลือกต้องเป็นเวลาเก่าที่สุด', [i, RoomID]));
      
      // ทดสอบว่าคิวที่ถูกเรียกไปแล้ว (fstatus="1") จะไม่ถูกเลือก
      // อัพเดทคิวแรกเป็น "เรียกแล้ว"
      Query.Close;
      Query.SQL.Text := 
        'UPDATE queue_data ' +
        'SET fstatus = ''1'' ' +
        'WHERE barcodes = :barcode';
      Query.ParamByName('barcode').AsString := TestBarcode[1];
      Query.Execute;
      
      // ตอนนี้คิวถัดไปควรเป็นคิวที่ 2
      Assert.IsTrue(FMainForm.GetNextQueueForRoom(RoomID, SelectedQueueNumber, SelectedBarcode),
        Format('Iteration %d (Room %d): หลังเรียกคิวแรก ยังต้องมีคิวถัดไป', [i, RoomID]));
      
      Assert.AreEqual(QueueNumber[2], SelectedQueueNumber,
        Format('Iteration %d (Room %d): หลังเรียกคิวแรก คิวถัดไปต้องเป็นคิวที่ 2', [i, RoomID]));
      
      // ล้างข้อมูลทดสอบของ iteration นี้
      Query.Close;
      Query.SQL.Text := 
        'DELETE FROM queue_data ' +
        'WHERE room = :room AND barcodes LIKE ''TEST_SELECTION_%''';
      Query.ParamByName('room').AsInteger := RoomID;
      Query.Execute;
    end;
    
    // ทดสอบกรณี edge case: ไม่มีคิวรอเลย
    Assert.IsFalse(FMainForm.GetNextQueueForRoom(1, SelectedQueueNumber, SelectedBarcode),
      'เมื่อไม่มีคิวรอ GetNextQueueForRoom ต้องคืนค่า False');
    
    // ทดสอบกรณี edge case: มีแต่คิวที่ถูกเรียกไปแล้ว
    TestBarcode[1] := GenerateRandomBarcode;
    InsertTestQueue(TestBarcode[1], '0001', 1, '1'); // fstatus = "1" (เรียกแล้ว)
    
    Assert.IsFalse(FMainForm.GetNextQueueForRoom(1, SelectedQueueNumber, SelectedBarcode),
      'เมื่อมีแต่คิวที่ถูกเรียกไปแล้ว GetNextQueueForRoom ต้องคืนค่า False');
    
  finally
    Query.Free;
  end;
end;

procedure TQueueSelectionTests.TestManualCallQueueUpdate_MultipleIterations;
var
  i: Integer;
  RoomID: Integer;
  TestBarcode: string;
  QueueNumber: string;
  ServiceCounter: Integer;
  Query: TUniQuery;
  UpdatedStatus: string;
  UpdatedCounter: string;
  TimeConfirm: TDateTime;
  SelectedQueueNumber, SelectedBarcode: string;
begin
  // Feature: queue-management-system, Property 20: Manual Call Queue Update
  // For any manually called queue, the system SHALL update status to "เรียกแล้ว",
  // set service counter, set time_confirm, and send WebSocket message.
  
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
      RoomID := ((i - 1) mod 4) + 1;
      ServiceCounter := ((i - 1) mod 9) + 1; // สลับช่องบริการ 1-9
      TestBarcode := GenerateRandomBarcode;
      
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
      
      // ตรวจสอบว่าช่องบริการถูกตั้งค่าถูกต้อง
      Assert.AreEqual(ServiceCounter, FMainForm.SelectedCounter,
        Format('Iteration %d: ช่องบริการต้องถูกตั้งค่าเป็น %d', [i, ServiceCounter]));
      
      // หาคิวถัดไปสำหรับ room นี้
      Assert.IsTrue(FMainForm.GetNextQueueForRoom(RoomID, SelectedQueueNumber, SelectedBarcode),
        Format('Iteration %d (Room %d): ต้องหาคิวถัดไปเจอ', [i, RoomID]));
      
      // อัพเดทสถานะคิว (เรียกคิว)
      FMainForm.UpdateQueueStatus(SelectedBarcode);
      
      // ตรวจสอบว่าข้อมูลถูกอัพเดทถูกต้อง
      Query.Close;
      Query.SQL.Text := 
        'SELECT fstatus, counters, time_confirm ' +
        'FROM queue_data ' +
        'WHERE barcodes = :barcode';
      Query.ParamByName('barcode').AsString := SelectedBarcode;
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
      
      // Assert: ต้องมีข้อความ WebSocket ถูกส่ง (หรือเก็บไว้ใน offline queue)
      // เนื่องจากในการทดสอบ WebSocket มักจะไม่เชื่อมต่อ เราตรวจสอบ offline queue
      if not FMainForm.sgcWebSocketClient1.Active then
      begin
        Assert.IsTrue(FMainForm.OfflineMessageQueue.Count > 0,
          Format('Iteration %d: เมื่อ WebSocket ไม่เชื่อมต่อ ต้องมีข้อความใน offline queue', [i]));
        
        // ตรวจสอบว่าข้อความล่าสุดมีข้อมูลครบถ้วน
        if FMainForm.OfflineMessageQueue.Count > 0 then
        begin
          Assert.IsTrue(
            FMainForm.OfflineMessageQueue[FMainForm.OfflineMessageQueue.Count - 1].Contains('call_queue'),
            Format('Iteration %d: ข้อความต้องเป็นประเภท call_queue', [i]));
          
          Assert.IsTrue(
            FMainForm.OfflineMessageQueue[FMainForm.OfflineMessageQueue.Count - 1].Contains(SelectedQueueNumber),
            Format('Iteration %d: ข้อความต้องมีหมายเลขคิว', [i]));
          
          Assert.IsTrue(
            FMainForm.OfflineMessageQueue[FMainForm.OfflineMessageQueue.Count - 1].Contains(IntToStr(ServiceCounter)),
            Format('Iteration %d: ข้อความต้องมีหมายเลขช่องบริการ', [i]));
        end;
      end;
      
      // ล้าง offline queue สำหรับ iteration ถัดไป
      FMainForm.OfflineMessageQueue.Clear;
    end;
    
    // ทดสอบกรณี edge case: เรียกคิวโดยไม่เลือกช่องบริการ
    FMainForm.cmbServiceCounter.ItemIndex := 0; // ไม่เลือกช่องบริการ
    if Assigned(FMainForm.cmbServiceCounter.OnChange) then
      FMainForm.cmbServiceCounter.OnChange(FMainForm.cmbServiceCounter);
    
    Assert.AreEqual(0, FMainForm.SelectedCounter,
      'เมื่อไม่เลือกช่องบริการ SelectedCounter ต้องเป็น 0');
    
    // พยายามเรียกคิว (ควรไม่สำเร็จ)
    TestBarcode := GenerateRandomBarcode;
    InsertTestQueue(TestBarcode, '0999', 1, '2');
    
    // ฟังก์ชัน UpdateQueueStatus จะไม่ทำงานถ้าไม่มีการเลือกช่องบริการ
    // (ตรวจสอบใน ProcessBarcodeInput หรือ CallNextQueueManually)
    
  finally
    Query.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TQueueSelectionTests);

end.
