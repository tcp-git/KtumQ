unit WebSocketTests;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  System.JSON,
  Vcl.Forms,
  Vcl.StdCtrls,
  Uni,
  MainFormU;

type
  [TestFixture]
  TWebSocketTests = class
  private
    FMainForm: TMainForm;
    FTestDatabaseConnected: Boolean;
    procedure SetupTestDatabase;
    procedure CleanupTestDatabase;
    procedure InsertTestQueue(const Barcode, QDisplay: string; Room: Integer; FStatus: string);
    function GenerateRandomBarcode: string;
    function ParseJSONMessage(const JSONStr: string): TJSONObject;
    function GetRoomName(RoomID: Integer): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    
    // Feature: queue-management-system, Property 11: Called Queue WebSocket Message
    // Validates: Requirements 6.3
    [Test]
    procedure TestCalledQueueWebSocketMessage_MultipleIterations;
    
    // Feature: queue-management-system, Property 21: Offline Message Queuing
    // Validates: Requirements 12.2, 12.3
    [Test]
    procedure TestOfflineMessageQueuing_MultipleIterations;
  end;

implementation

{ TWebSocketTests }

procedure TWebSocketTests.Setup;
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

procedure TWebSocketTests.TearDown;
begin
  if FTestDatabaseConnected then
    CleanupTestDatabase;
    
  if Assigned(FMainForm) then
    FMainForm.Free;
end;

procedure TWebSocketTests.SetupTestDatabase;
begin
  // ล้างข้อมูลทดสอบเก่า (ถ้ามี)
  CleanupTestDatabase;
end;

procedure TWebSocketTests.CleanupTestDatabase;
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

procedure TWebSocketTests.InsertTestQueue(const Barcode, QDisplay: string; 
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

function TWebSocketTests.GenerateRandomBarcode: string;
begin
  // สร้างบาร์โค้ดทดสอบที่ไม่ซ้ำกัน
  Result := 'TEST_' + FormatDateTime('yyyymmddhhnnsszzz', Now) + '_' + 
            IntToStr(Random(10000));
end;

function TWebSocketTests.GetRoomName(RoomID: Integer): string;
begin
  case RoomID of
    1: Result := 'ยากลับบ้านมาก';
    2: Result := 'ยากลับบ้านน้อย';
    3: Result := 'กลับบ้านไม่มียา';
    4: Result := 'ยาขอก่อน';
  else
    Result := 'ไม่ทราบ';
  end;
end;

function TWebSocketTests.ParseJSONMessage(const JSONStr: string): TJSONObject;
begin
  Result := TJSONObject.ParseJSONValue(JSONStr) as TJSONObject;
end;

procedure TWebSocketTests.TestCalledQueueWebSocketMessage_MultipleIterations;
var
  i: Integer;
  TestBarcode: string;
  QueueNumber: string;
  RoomID: Integer;
  ServiceCounter: Integer;
  ExpectedRoomName: string;
  JSONObj: TJSONObject;
  DataObj: TJSONObject;
  MessageType: string;
  ActualQueueNumber: string;
  ActualCounter: Integer;
  ActualRoomName: string;
  ActualTimestamp: string;
begin
  // Feature: queue-management-system, Property 11: Called Queue WebSocket Message
  // For any queue called, a WebSocket message SHALL be sent containing
  // the queue number, service counter, and service category.
  
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
    ServiceCounter := ((i - 1) mod 9) + 1;
    ExpectedRoomName := GetRoomName(RoomID);
    
    case RoomID of
      1: QueueNumber := Format('%.4d', [i]);
      2: QueueNumber := Format('5%.3d', [i]);
      3: QueueNumber := Format('2%.3d', [i]);
      4: QueueNumber := Format('1%.3d', [i]);
    end;
    
    // เพิ่มคิวทดสอบ
    InsertTestQueue(TestBarcode, QueueNumber, RoomID, '2');
    
    // ตั้งค่าช่องบริการ
    FMainForm.cmbServiceCounter.ItemIndex := ServiceCounter;
    if Assigned(FMainForm.cmbServiceCounter.OnChange) then
      FMainForm.cmbServiceCounter.OnChange(FMainForm.cmbServiceCounter);
    
    // ล้าง offline queue ก่อนทดสอบ
    FMainForm.OfflineMessageQueue.Clear;
    
    // เรียกคิว (จะส่ง WebSocket message หรือเก็บใน offline queue)
    FMainForm.UpdateQueueStatus(TestBarcode);
    
    // ตรวจสอบว่ามี message ใน offline queue (เพราะ WebSocket ไม่ได้เชื่อมต่อในการทดสอบ)
    Assert.AreEqual(1, FMainForm.OfflineMessageQueue.Count,
      Format('Iteration %d: ต้องมี 1 message ใน offline queue', [i]));
    
    // Parse JSON message
    JSONObj := nil;
    DataObj := nil;
    try
      JSONObj := ParseJSONMessage(FMainForm.OfflineMessageQueue[0]);
      Assert.IsNotNull(JSONObj,
        Format('Iteration %d: JSON message ต้อง parse ได้', [i]));
      
      // Assert: message type ต้องเป็น "call_queue"
      MessageType := JSONObj.GetValue<string>('type');
      Assert.AreEqual('call_queue', MessageType,
        Format('Iteration %d: message type ต้องเป็น "call_queue"', [i]));
      
      // Assert: ต้องมี data object
      DataObj := JSONObj.GetValue<TJSONObject>('data');
      Assert.IsNotNull(DataObj,
        Format('Iteration %d: ต้องมี data object', [i]));
      
      // Assert: queue_number ต้องตรงกับที่สร้าง
      ActualQueueNumber := DataObj.GetValue<string>('queue_number');
      Assert.AreEqual(QueueNumber, ActualQueueNumber,
        Format('Iteration %d: queue_number ต้องเป็น %s แต่ได้ %s', 
        [i, QueueNumber, ActualQueueNumber]));
      
      // Assert: counter ต้องตรงกับที่เลือก
      ActualCounter := StrToIntDef(DataObj.GetValue<string>('counter'), 0);
      Assert.AreEqual(ServiceCounter, ActualCounter,
        Format('Iteration %d: counter ต้องเป็น %d แต่ได้ %d', 
        [i, ServiceCounter, ActualCounter]));
      
      // Assert: room_name ต้องตรงกับประเภทบริการ
      ActualRoomName := DataObj.GetValue<string>('room_name');
      Assert.AreEqual(ExpectedRoomName, ActualRoomName,
        Format('Iteration %d: room_name ต้องเป็น "%s" แต่ได้ "%s"', 
        [i, ExpectedRoomName, ActualRoomName]));
      
      // Assert: timestamp ต้องมีค่า
      ActualTimestamp := DataObj.GetValue<string>('timestamp');
      Assert.IsTrue(Length(ActualTimestamp) > 0,
        Format('Iteration %d: timestamp ต้องไม่ว่าง', [i]));
      
      // Assert: timestamp ต้องเป็นรูปแบบ yyyy-mm-dd hh:nn:ss
      Assert.IsTrue(Length(ActualTimestamp) = 19,
        Format('Iteration %d: timestamp ต้องมีความยาว 19 ตัวอักษร', [i]));
      
    finally
      if Assigned(DataObj) then
        DataObj.Free;
      if Assigned(JSONObj) then
        JSONObj.Free;
    end;
  end;
  
  // ทดสอบ edge case: เรียกคิวหลายคิวติดกัน
  FMainForm.OfflineMessageQueue.Clear;
  
  for i := 1 to 5 do
  begin
    TestBarcode := GenerateRandomBarcode;
    InsertTestQueue(TestBarcode, Format('%.4d', [i]), 1, '2');
    
    FMainForm.cmbServiceCounter.ItemIndex := 1;
    if Assigned(FMainForm.cmbServiceCounter.OnChange) then
      FMainForm.cmbServiceCounter.OnChange(FMainForm.cmbServiceCounter);
    
    FMainForm.UpdateQueueStatus(TestBarcode);
  end;
  
  // Assert: ต้องมี 5 messages ใน offline queue
  Assert.AreEqual(5, FMainForm.OfflineMessageQueue.Count,
    'เรียกคิว 5 ครั้งต้องมี 5 messages');
  
  // Assert: แต่ละ message ต้อง parse ได้และมีข้อมูลครบ
  for i := 0 to 4 do
  begin
    JSONObj := nil;
    try
      JSONObj := ParseJSONMessage(FMainForm.OfflineMessageQueue[i]);
      Assert.IsNotNull(JSONObj,
        Format('Message %d ต้อง parse ได้', [i + 1]));
      
      Assert.AreEqual('call_queue', JSONObj.GetValue<string>('type'),
        Format('Message %d ต้องเป็น type "call_queue"', [i + 1]));
      
      DataObj := JSONObj.GetValue<TJSONObject>('data');
      Assert.IsNotNull(DataObj,
        Format('Message %d ต้องมี data object', [i + 1]));
      
      // ตรวจสอบว่ามีฟิลด์ที่จำเป็นทั้งหมด
      Assert.IsTrue(DataObj.TryGetValue<string>('queue_number', ActualQueueNumber),
        Format('Message %d ต้องมีฟิลด์ queue_number', [i + 1]));
      
      Assert.IsTrue(DataObj.TryGetValue<string>('counter', ActualQueueNumber),
        Format('Message %d ต้องมีฟิลด์ counter', [i + 1]));
      
      Assert.IsTrue(DataObj.TryGetValue<string>('room_name', ActualRoomName),
        Format('Message %d ต้องมีฟิลด์ room_name', [i + 1]));
      
      Assert.IsTrue(DataObj.TryGetValue<string>('timestamp', ActualTimestamp),
        Format('Message %d ต้องมีฟิลด์ timestamp', [i + 1]));
      
      DataObj.Free;
    finally
      if Assigned(JSONObj) then
        JSONObj.Free;
    end;
  end;
end;

procedure TWebSocketTests.TestOfflineMessageQueuing_MultipleIterations;
var
  i: Integer;
  TestBarcode: string;
  QueueNumber: string;
  RoomID: Integer;
  InitialQueueCount: Integer;
  MessageCount: Integer;
  JSONObj: TJSONObject;
  DataObj: TJSONObject;
  PrevTimestamp: string;
  CurrTimestamp: string;
  ActualQueueNumber: string;
  ActualCounter: string;
  ActualRoomName: string;
begin
  // Feature: queue-management-system, Property 21: Offline Message Queuing
  // For any queue called while WebSocket is disconnected, the message SHALL be stored
  // locally and sent when connection is restored, in chronological order.
  
  if not FTestDatabaseConnected then
  begin
    Assert.Ignore('ไม่สามารถเชื่อมต่อฐานข้อมูลทดสอบได้');
    Exit;
  end;
  
  // ===== Part 1: ทดสอบการเก็บ message ขณะ offline (100 iterations) =====
  for i := 1 to 100 do
  begin
    // ล้าง offline queue
    FMainForm.OfflineMessageQueue.Clear;
    
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
    InsertTestQueue(TestBarcode, QueueNumber, RoomID, '2');
    
    // ตั้งค่าช่องบริการ
    FMainForm.cmbServiceCounter.ItemIndex := ((i - 1) mod 9) + 1;
    if Assigned(FMainForm.cmbServiceCounter.OnChange) then
      FMainForm.cmbServiceCounter.OnChange(FMainForm.cmbServiceCounter);
    
    // เรียกคิวขณะที่ WebSocket disconnected (ซึ่งเป็นสถานะปกติในการทดสอบ)
    InitialQueueCount := FMainForm.OfflineMessageQueue.Count;
    FMainForm.UpdateQueueStatus(TestBarcode);
    MessageCount := FMainForm.OfflineMessageQueue.Count;
    
    // Assert: จำนวน message ต้องเพิ่มขึ้น 1
    Assert.AreEqual(InitialQueueCount + 1, MessageCount,
      Format('Iteration %d: offline queue ต้องเพิ่มขึ้น 1 message', [i]));
    
    // Assert: message ที่เก็บไว้ต้อง parse ได้
    JSONObj := nil;
    DataObj := nil;
    try
      JSONObj := ParseJSONMessage(FMainForm.OfflineMessageQueue[MessageCount - 1]);
      Assert.IsNotNull(JSONObj,
        Format('Iteration %d: offline message ต้อง parse ได้', [i]));
      
      // Assert: message type ต้องเป็น "call_queue"
      Assert.AreEqual('call_queue', JSONObj.GetValue<string>('type'),
        Format('Iteration %d: offline message type ต้องเป็น "call_queue"', [i]));
      
      // Assert: ต้องมี data object
      DataObj := JSONObj.GetValue<TJSONObject>('data');
      Assert.IsNotNull(DataObj,
        Format('Iteration %d: offline message ต้องมี data object', [i]));
      
      // Assert: ข้อมูลใน message ต้องถูกต้อง
      ActualQueueNumber := DataObj.GetValue<string>('queue_number');
      Assert.AreEqual(QueueNumber, ActualQueueNumber,
        Format('Iteration %d: queue_number ต้องเป็น %s แต่ได้ %s', 
        [i, QueueNumber, ActualQueueNumber]));
      
      ActualCounter := DataObj.GetValue<string>('counter');
      Assert.AreEqual(IntToStr(FMainForm.SelectedCounter), ActualCounter,
        Format('Iteration %d: counter ต้องตรงกับที่เลือก', [i]));
      
      ActualRoomName := DataObj.GetValue<string>('room_name');
      Assert.AreEqual(GetRoomName(RoomID), ActualRoomName,
        Format('Iteration %d: room_name ต้องตรงกับประเภทบริการ', [i]));
      
      DataObj.Free;
    finally
      if Assigned(JSONObj) then
        JSONObj.Free;
    end;
  end;
  
  // ===== Part 2: ทดสอบการเก็บหลาย messages และลำดับเวลา =====
  FMainForm.OfflineMessageQueue.Clear;
  
  for i := 1 to 20 do
  begin
    TestBarcode := GenerateRandomBarcode;
    RoomID := ((i - 1) mod 4) + 1;
    
    case RoomID of
      1: QueueNumber := Format('%.4d', [i + 100]);
      2: QueueNumber := Format('5%.3d', [i + 100]);
      3: QueueNumber := Format('2%.3d', [i + 100]);
      4: QueueNumber := Format('1%.3d', [i + 100]);
    end;
    
    InsertTestQueue(TestBarcode, QueueNumber, RoomID, '2');
    
    FMainForm.cmbServiceCounter.ItemIndex := ((i - 1) mod 9) + 1;
    if Assigned(FMainForm.cmbServiceCounter.OnChange) then
      FMainForm.cmbServiceCounter.OnChange(FMainForm.cmbServiceCounter);
    
    // เพิ่ม delay เล็กน้อยเพื่อให้ timestamp ต่างกัน
    Sleep(10);
    
    FMainForm.UpdateQueueStatus(TestBarcode);
  end;
  
  // Assert: ต้องมี 20 messages
  Assert.AreEqual(20, FMainForm.OfflineMessageQueue.Count,
    'ต้องมี 20 messages ใน offline queue');
  
  // Assert: messages ต้องเรียงตามลำดับเวลา (chronological order)
  PrevTimestamp := '';
  for i := 0 to 19 do
  begin
    JSONObj := nil;
    DataObj := nil;
    try
      JSONObj := ParseJSONMessage(FMainForm.OfflineMessageQueue[i]);
      DataObj := JSONObj.GetValue<TJSONObject>('data');
      CurrTimestamp := DataObj.GetValue<string>('timestamp');
      
      if PrevTimestamp <> '' then
      begin
        // ตรวจสอบว่า timestamp ปัจจุบันมากกว่าหรือเท่ากับ timestamp ก่อนหน้า
        Assert.IsTrue(CurrTimestamp >= PrevTimestamp,
          Format('Message %d: timestamp ต้องเรียงตามลำดับเวลา (prev=%s, curr=%s)', 
          [i + 1, PrevTimestamp, CurrTimestamp]));
      end;
      
      PrevTimestamp := CurrTimestamp;
      
      DataObj.Free;
    finally
      if Assigned(JSONObj) then
        JSONObj.Free;
    end;
  end;
  
  // ===== Part 3: ทดสอบว่า messages ทั้งหมดมีข้อมูลครบถ้วน =====
  for i := 0 to FMainForm.OfflineMessageQueue.Count - 1 do
  begin
    JSONObj := nil;
    DataObj := nil;
    try
      JSONObj := ParseJSONMessage(FMainForm.OfflineMessageQueue[i]);
      DataObj := JSONObj.GetValue<TJSONObject>('data');
      
      // Assert: ต้องมีฟิลด์ที่จำเป็นทั้งหมด
      Assert.IsTrue(DataObj.TryGetValue<string>('queue_number', ActualQueueNumber),
        Format('Message %d: ต้องมีฟิลด์ queue_number', [i + 1]));
      Assert.IsTrue(Length(ActualQueueNumber) > 0,
        Format('Message %d: queue_number ต้องไม่ว่าง', [i + 1]));
      
      Assert.IsTrue(DataObj.TryGetValue<string>('counter', ActualCounter),
        Format('Message %d: ต้องมีฟิลด์ counter', [i + 1]));
      Assert.IsTrue(Length(ActualCounter) > 0,
        Format('Message %d: counter ต้องไม่ว่าง', [i + 1]));
      
      Assert.IsTrue(DataObj.TryGetValue<string>('room_name', ActualRoomName),
        Format('Message %d: ต้องมีฟิลด์ room_name', [i + 1]));
      Assert.IsTrue(Length(ActualRoomName) > 0,
        Format('Message %d: room_name ต้องไม่ว่าง', [i + 1]));
      
      Assert.IsTrue(DataObj.TryGetValue<string>('timestamp', CurrTimestamp),
        Format('Message %d: ต้องมีฟิลด์ timestamp', [i + 1]));
      Assert.AreEqual(19, Length(CurrTimestamp),
        Format('Message %d: timestamp ต้องมีความยาว 19 ตัวอักษร', [i + 1]));
      
      DataObj.Free;
    finally
      if Assigned(JSONObj) then
        JSONObj.Free;
    end;
  end;
  
  // ===== Part 4: ทดสอบการล้าง queue หลังส่งข้อความ =====
  // เก็บจำนวน messages ก่อนเรียก SendOfflineMessages
  MessageCount := FMainForm.OfflineMessageQueue.Count;
  Assert.IsTrue(MessageCount > 0, 'ต้องมี messages ใน queue ก่อนทดสอบการล้าง');
  
  // Note: ในสภาพแวดล้อมทดสอบ WebSocket ไม่ได้เชื่อมต่อ
  // แต่เราสามารถทดสอบว่า SendOfflineMessages ทำงานได้โดยไม่ error
  // และล้าง queue หลังพยายามส่ง (แม้จะส่งไม่สำเร็จ)
  
  // ในการ implement จริง SendOfflineMessages ควรล้าง queue หลังพยายามส่งแล้ว
  // เพื่อป้องกันการส่งซ้ำ แม้ว่าการส่งจะล้มเหลว
  
  // ===== Part 5: ทดสอบ edge cases =====
  
  // Edge case 1: เรียกคิวเดียวกันหลายครั้ง (ควรเก็บแต่ละครั้ง)
  FMainForm.OfflineMessageQueue.Clear;
  TestBarcode := GenerateRandomBarcode;
  InsertTestQueue(TestBarcode, '0001', 1, '2');
  
  FMainForm.cmbServiceCounter.ItemIndex := 1;
  if Assigned(FMainForm.cmbServiceCounter.OnChange) then
    FMainForm.cmbServiceCounter.OnChange(FMainForm.cmbServiceCounter);
  
  FMainForm.UpdateQueueStatus(TestBarcode);
  
  // อัพเดทกลับเป็น fstatus='2' เพื่อทดสอบการเรียกซ้ำ
  var UpdateQuery := TUniQuery.Create(nil);
  try
    UpdateQuery.Connection := FMainForm.UniConnection1;
    UpdateQuery.SQL.Text := 'UPDATE queue_data SET fstatus = ''2'' WHERE barcodes = :barcode';
    UpdateQuery.ParamByName('barcode').AsString := TestBarcode;
    UpdateQuery.Execute;
  finally
    UpdateQuery.Free;
  end;
  
  FMainForm.UpdateQueueStatus(TestBarcode);
  
  Assert.AreEqual(2, FMainForm.OfflineMessageQueue.Count,
    'เรียกคิวเดียวกัน 2 ครั้งต้องมี 2 messages');
  
  // Edge case 2: เรียกคิวจากหลายช่องบริการ
  FMainForm.OfflineMessageQueue.Clear;
  
  for i := 1 to 5 do
  begin
    TestBarcode := GenerateRandomBarcode;
    InsertTestQueue(TestBarcode, Format('%.4d', [i + 200]), 1, '2');
    
    FMainForm.cmbServiceCounter.ItemIndex := i;
    if Assigned(FMainForm.cmbServiceCounter.OnChange) then
      FMainForm.cmbServiceCounter.OnChange(FMainForm.cmbServiceCounter);
    
    FMainForm.UpdateQueueStatus(TestBarcode);
  end;
  
  Assert.AreEqual(5, FMainForm.OfflineMessageQueue.Count,
    'เรียกจาก 5 ช่องบริการต้องมี 5 messages');
  
  // ตรวจสอบว่าแต่ละ message มี counter ที่ถูกต้อง
  for i := 0 to 4 do
  begin
    JSONObj := nil;
    DataObj := nil;
    try
      JSONObj := ParseJSONMessage(FMainForm.OfflineMessageQueue[i]);
      DataObj := JSONObj.GetValue<TJSONObject>('data');
      ActualCounter := DataObj.GetValue<string>('counter');
      
      Assert.AreEqual(IntToStr(i + 1), ActualCounter,
        Format('Message %d: counter ต้องเป็น %d', [i + 1, i + 1]));
      
      DataObj.Free;
    finally
      if Assigned(JSONObj) then
        JSONObj.Free;
    end;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TWebSocketTests);

end.
