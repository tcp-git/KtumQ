unit PriorityQueueTests;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  Vcl.Forms,
  Uni,
  MainFormU;

type
  [TestFixture]
  TPriorityQueueTests = class
  private
    FMainForm: TMainForm;
    FTestDatabaseConnected: Boolean;
    procedure SetupTestDatabase;
    procedure CleanupTestDatabase;
    procedure InsertTestQueue(const Barcode, QDisplay: string; Room: Integer; 
      FStatus: string; Period: string = '0');
    function GenerateRandomBarcode: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    
    // Feature: queue-management-system, Property 13: Priority Queue Marking
    // Validates: Requirements 8.1, 8.2
    [Test]
    procedure TestPriorityQueueMarking_MultipleIterations;
    
    // Feature: queue-management-system, Property 14: Priority Queue WebSocket Notification
    // Validates: Requirements 8.3
    [Test]
    procedure TestPriorityQueueWebSocketNotification_MultipleIterations;
  end;

implementation

{ TPriorityQueueTests }

procedure TPriorityQueueTests.Setup;
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

procedure TPriorityQueueTests.TearDown;
begin
  if FTestDatabaseConnected then
    CleanupTestDatabase;
    
  if Assigned(FMainForm) then
    FMainForm.Free;
end;

procedure TPriorityQueueTests.SetupTestDatabase;
begin
  // ล้างข้อมูลทดสอบเก่า
  CleanupTestDatabase;
end;

procedure TPriorityQueueTests.CleanupTestDatabase;
var
  Query: TUniQuery;
begin
  try
    Query := TUniQuery.Create(nil);
    try
      Query.Connection := FMainForm.UniConnection1;
      Query.SQL.Text := 'DELETE FROM queue_data WHERE barcodes LIKE ''TEST_PRIORITY_%''';
      Query.Execute;
    finally
      Query.Free;
    end;
  except
    // ละเว้นข้อผิดพลาดในการล้างข้อมูล
  end;
end;

procedure TPriorityQueueTests.InsertTestQueue(const Barcode, QDisplay: string; 
  Room: Integer; FStatus: string; Period: string = '0');
var
  Query: TUniQuery;
begin
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := FMainForm.UniConnection1;
    Query.SQL.Text := 
      'INSERT INTO queue_data (qdisplay, room, prefix, qid, fstatus, barcodes, period, timestamp) ' +
      'VALUES (:qdisplay, :room, :prefix, :qid, :fstatus, :barcode, :period, NOW())';
    Query.ParamByName('qdisplay').AsString := QDisplay;
    Query.ParamByName('room').AsInteger := Room;
    Query.ParamByName('prefix').AsString := Copy(QDisplay, 1, 1);
    Query.ParamByName('qid').AsInteger := StrToIntDef(Copy(QDisplay, 2, 3), 1);
    Query.ParamByName('fstatus').AsString := FStatus;
    Query.ParamByName('barcode').AsString := Barcode;
    Query.ParamByName('period').AsString := Period;
    Query.Execute;
  finally
    Query.Free;
  end;
end;

function TPriorityQueueTests.GenerateRandomBarcode: string;
begin
  // สร้างบาร์โค้ดทดสอบที่ไม่ซ้ำกัน
  Result := 'TEST_PRIORITY_' + FormatDateTime('yyyymmddhhnnsszzz', Now) + '_' + 
            IntToStr(Random(10000));
end;

procedure TPriorityQueueTests.TestPriorityQueueMarking_MultipleIterations;
var
  i: Integer;
  TestBarcode: string;
  QueueNumber: string;
  RoomID: Integer;
  Query: TUniQuery;
  UpdatedPeriod: string;
  TimeStampBefore, TimeStampAfter: TDateTime;
begin
  // Feature: queue-management-system, Property 13: Priority Queue Marking
  // For any queue marked as priority, the period field in database
  // SHALL be set to "1" and a timestamp SHALL be recorded.
  
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
      
      case RoomID of
        1: QueueNumber := Format('%.4d', [i]);
        2: QueueNumber := Format('5%.3d', [i]);
        3: QueueNumber := Format('2%.3d', [i]);
        4: QueueNumber := Format('1%.3d', [i]);
      end;
      
      // เพิ่มคิวทดสอบ (period = "0" = ไม่ใช่คิวรอนาน)
      InsertTestQueue(TestBarcode, QueueNumber, RoomID, '2', '0');
      
      // บันทึกเวลาก่อนทำเครื่องหมาย
      TimeStampBefore := Now;
      
      // ทำเครื่องหมายคิวรอนาน
      FMainForm.MarkQueueAsPriority(TestBarcode);
      
      // บันทึกเวลาหลังทำเครื่องหมาย
      TimeStampAfter := Now;
      
      // ตรวจสอบว่าข้อมูลถูกอัพเดทถูกต้อง
      Query.Close;
      Query.SQL.Text := 
        'SELECT period, timestamp ' +
        'FROM queue_data ' +
        'WHERE barcodes = :barcode';
      Query.ParamByName('barcode').AsString := TestBarcode;
      Query.Open;
      
      // Assert: ต้องมีข้อมูล
      Assert.IsFalse(Query.IsEmpty,
        Format('Iteration %d: ต้องพบข้อมูลคิวหลังทำเครื่องหมาย', [i]));
      
      // Assert: period ต้องเป็น "1" (คิวรอนาน)
      UpdatedPeriod := Query.FieldByName('period').AsString;
      Assert.AreEqual('1', UpdatedPeriod,
        Format('Iteration %d: period ต้องเป็น "1" (คิวรอนาน) แต่ได้ "%s"', 
        [i, UpdatedPeriod]));
      
      // Assert: timestamp ต้องไม่เป็น NULL
      Assert.IsFalse(Query.FieldByName('timestamp').IsNull,
        Format('Iteration %d: timestamp ต้องไม่เป็น NULL', [i]));
      
      // Assert: timestamp ต้องอยู่ระหว่างเวลาก่อนและหลังการทำเครื่องหมาย
      // (ยอมให้ผิดพลาด 5 วินาที)
      Assert.IsTrue(
        Query.FieldByName('timestamp').AsDateTime >= (TimeStampBefore - (5 / SecsPerDay)),
        Format('Iteration %d: timestamp ต้องไม่น้อยกว่าเวลาก่อนทำเครื่องหมาย', [i]));
      
      Assert.IsTrue(
        Query.FieldByName('timestamp').AsDateTime <= (TimeStampAfter + (5 / SecsPerDay)),
        Format('Iteration %d: timestamp ต้องไม่มากกว่าเวลาหลังทำเครื่องหมาย', [i]));
    end;
    
    // ทดสอบกรณี edge case: ทำเครื่องหมายคิวเดียวกันหลายครั้ง
    TestBarcode := GenerateRandomBarcode;
    InsertTestQueue(TestBarcode, '0999', 1, '2', '0');
    
    // ทำเครื่องหมายครั้งแรก
    FMainForm.MarkQueueAsPriority(TestBarcode);
    
    Query.Close;
    Query.SQL.Text := 'SELECT period FROM queue_data WHERE barcodes = :barcode';
    Query.ParamByName('barcode').AsString := TestBarcode;
    Query.Open;
    Assert.AreEqual('1', Query.FieldByName('period').AsString,
      'หลังทำเครื่องหมายครั้งแรก period ต้องเป็น "1"');
    
    // ทำเครื่องหมายอีกครั้ง (ควรยังคงเป็น "1")
    FMainForm.MarkQueueAsPriority(TestBarcode);
    
    Query.Close;
    Query.SQL.Text := 'SELECT period FROM queue_data WHERE barcodes = :barcode';
    Query.ParamByName('barcode').AsString := TestBarcode;
    Query.Open;
    Assert.AreEqual('1', Query.FieldByName('period').AsString,
      'หลังทำเครื่องหมายซ้ำ period ต้องยังคงเป็น "1"');
    
  finally
    Query.Free;
  end;
end;

procedure TPriorityQueueTests.TestPriorityQueueWebSocketNotification_MultipleIterations;
var
  i: Integer;
  TestBarcode: string;
  QueueNumber: string;
  RoomID: Integer;
  MessageCountBefore, MessageCountAfter: Integer;
begin
  // Feature: queue-management-system, Property 14: Priority Queue WebSocket Notification
  // For any queue marked as priority, a WebSocket message
  // SHALL be sent to update the priority queue display.
  
  if not FTestDatabaseConnected then
  begin
    Assert.Ignore('ไม่สามารถเชื่อมต่อฐานข้อมูลทดสอบได้');
    Exit;
  end;
  
  // ทดสอบ 100 iterations
  for i := 1 to 100 do
  begin
    // สร้างข้อมูลทดสอบ
    TestBarcode := GenerateRandomBarcode;
    RoomID := ((i - 1) mod 4) + 1;
    
    case RoomID of
      1: QueueNumber := Format('%.4d', [i]);
      2: QueueNumber := Format('5%.3d', [i]);
      3: QueueNumber := Format('2%.3d', [i]);
      4: QueueNumber := Format('1%.3d', [i]);
    end;
    
    // เพิ่มคิวทดสอบ
    InsertTestQueue(TestBarcode, QueueNumber, RoomID, '2', '0');
    
    // นับจำนวนข้อความใน offline queue ก่อนทำเครื่องหมาย
    MessageCountBefore := FMainForm.OfflineMessageQueue.Count;
    
    // ทำเครื่องหมายคิวรอนาน
    FMainForm.MarkQueueAsPriority(TestBarcode);
    
    // นับจำนวนข้อความหลังทำเครื่องหมาย
    MessageCountAfter := FMainForm.OfflineMessageQueue.Count;
    
    // Assert: ถ้า WebSocket ไม่เชื่อมต่อ ต้องมีข้อความเพิ่มขึ้นใน offline queue
    // (เนื่องจากในการทดสอบ WebSocket มักจะไม่เชื่อมต่อ)
    if not FMainForm.sgcWebSocketClient1.Active then
    begin
      Assert.IsTrue(MessageCountAfter > MessageCountBefore,
        Format('Iteration %d: เมื่อ WebSocket ไม่เชื่อมต่อ ต้องมีข้อความเพิ่มใน offline queue', [i]));
      
      // Assert: ข้อความล่าสุดต้องเป็น priority queue update
      if FMainForm.OfflineMessageQueue.Count > 0 then
      begin
        Assert.IsTrue(
          FMainForm.OfflineMessageQueue[FMainForm.OfflineMessageQueue.Count - 1].Contains('priority_queue'),
          Format('Iteration %d: ข้อความล่าสุดต้องเป็น priority queue update', [i]));
        
        Assert.IsTrue(
          FMainForm.OfflineMessageQueue[FMainForm.OfflineMessageQueue.Count - 1].Contains(QueueNumber),
          Format('Iteration %d: ข้อความต้องมีหมายเลขคิว %s', [i, QueueNumber]));
      end;
    end;
  end;
  
  // ทดสอบว่าข้อความมี format ที่ถูกต้อง
  if FMainForm.OfflineMessageQueue.Count > 0 then
  begin
    // ตรวจสอบข้อความล่าสุด
    Assert.IsTrue(
      FMainForm.OfflineMessageQueue[FMainForm.OfflineMessageQueue.Count - 1].Contains('"type"'),
      'ข้อความ WebSocket ต้องมี field "type"');
    
    Assert.IsTrue(
      FMainForm.OfflineMessageQueue[FMainForm.OfflineMessageQueue.Count - 1].Contains('"data"'),
      'ข้อความ WebSocket ต้องมี field "data"');
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TPriorityQueueTests);

end.
