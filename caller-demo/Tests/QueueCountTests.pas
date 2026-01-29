unit QueueCountTests;

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
  TQueueCountTests = class
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
    
    // Feature: queue-management-system, Property 16: Waiting Queue Count Accuracy
    // Validates: Requirements 9.5, 10.1
    [Test]
    procedure TestWaitingQueueCountAccuracy_MultipleIterations;
  end;

implementation

{ TQueueCountTests }

procedure TQueueCountTests.Setup;
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

procedure TQueueCountTests.TearDown;
begin
  if FTestDatabaseConnected then
    CleanupTestDatabase;
    
  if Assigned(FMainForm) then
    FMainForm.Free;
end;

procedure TQueueCountTests.SetupTestDatabase;
begin
  // ล้างข้อมูลทดสอบเก่า
  CleanupTestDatabase;
end;

procedure TQueueCountTests.CleanupTestDatabase;
var
  Query: TUniQuery;
begin
  try
    Query := TUniQuery.Create(nil);
    try
      Query.Connection := FMainForm.UniConnection1;
      Query.SQL.Text := 'DELETE FROM queue_data WHERE barcodes LIKE ''TEST_COUNT_%''';
      Query.Execute;
    finally
      Query.Free;
    end;
  except
    // ละเว้นข้อผิดพลาดในการล้างข้อมูล
  end;
end;

procedure TQueueCountTests.InsertTestQueue(const Barcode, QDisplay: string; 
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

function TQueueCountTests.GenerateRandomBarcode: string;
begin
  // สร้างบาร์โค้ดทดสอบที่ไม่ซ้ำกัน
  Result := 'TEST_COUNT_' + FormatDateTime('yyyymmddhhnnsszzz', Now) + '_' + 
            IntToStr(Random(10000));
end;

procedure TQueueCountTests.TestWaitingQueueCountAccuracy_MultipleIterations;
var
  i, j: Integer;
  RoomID: Integer;
  ExpectedWaitingCount: Integer;
  ActualWaitingCount: Integer;
  NumWaitingQueues: Integer;
  NumCalledQueues: Integer;
  TestBarcode: string;
  QueueNumber: string;
  Query: TUniQuery;
  DirectQueryCount: Integer;
begin
  // Feature: queue-management-system, Property 16: Waiting Queue Count Accuracy
  // For any service category, the count of waiting queues SHALL equal
  // the number of queues with fstatus="2" for that room value.
  
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
      
      // สุ่มจำนวนคิวรอและคิวที่เรียกแล้ว (0-10 คิวแต่ละประเภท)
      NumWaitingQueues := Random(11); // 0-10
      NumCalledQueues := Random(11);  // 0-10
      
      ExpectedWaitingCount := NumWaitingQueues;
      
      // สร้างคิวรอ (fstatus = "2")
      for j := 1 to NumWaitingQueues do
      begin
        TestBarcode := GenerateRandomBarcode;
        
        case RoomID of
          1: QueueNumber := Format('%.4d', [(i-1)*20 + j]);
          2: QueueNumber := Format('5%.3d', [(i-1)*20 + j]);
          3: QueueNumber := Format('2%.3d', [(i-1)*20 + j]);
          4: QueueNumber := Format('1%.3d', [(i-1)*20 + j]);
        end;
        
        InsertTestQueue(TestBarcode, QueueNumber, RoomID, '2');
        Sleep(5); // รอเล็กน้อยเพื่อให้ timestamp ต่างกัน
      end;
      
      // สร้างคิวที่เรียกแล้ว (fstatus = "1")
      for j := 1 to NumCalledQueues do
      begin
        TestBarcode := GenerateRandomBarcode;
        
        case RoomID of
          1: QueueNumber := Format('%.4d', [(i-1)*20 + NumWaitingQueues + j]);
          2: QueueNumber := Format('5%.3d', [(i-1)*20 + NumWaitingQueues + j]);
          3: QueueNumber := Format('2%.3d', [(i-1)*20 + NumWaitingQueues + j]);
          4: QueueNumber := Format('1%.3d', [(i-1)*20 + NumWaitingQueues + j]);
        end;
        
        InsertTestQueue(TestBarcode, QueueNumber, RoomID, '1');
        Sleep(5);
      end;
      
      // ตรวจสอบจำนวนคิวรอจาก GetWaitingQueueCount
      ActualWaitingCount := FMainForm.GetWaitingQueueCount(RoomID);
      
      // ตรวจสอบจำนวนคิวรอโดยตรงจากฐานข้อมูล
      Query.Close;
      Query.SQL.Text := 
        'SELECT COUNT(*) as queue_count ' +
        'FROM queue_data ' +
        'WHERE room = :room AND fstatus = ''2'' AND barcodes LIKE ''TEST_COUNT_%''';
      Query.ParamByName('room').AsInteger := RoomID;
      Query.Open;
      
      DirectQueryCount := Query.FieldByName('queue_count').AsInteger;
      
      // Assert: จำนวนคิวรอจาก GetWaitingQueueCount ต้องตรงกับที่คาดหวัง
      Assert.AreEqual(ExpectedWaitingCount, ActualWaitingCount,
        Format('Iteration %d (Room %d): จำนวนคิวรอจาก GetWaitingQueueCount (%d) ต้องตรงกับที่คาดหวัง (%d)',
        [i, RoomID, ActualWaitingCount, ExpectedWaitingCount]));
      
      // Assert: จำนวนคิวรอจาก GetWaitingQueueCount ต้องตรงกับ direct query
      Assert.AreEqual(DirectQueryCount, ActualWaitingCount,
        Format('Iteration %d (Room %d): จำนวนคิวรอจาก GetWaitingQueueCount (%d) ต้องตรงกับ direct query (%d)',
        [i, RoomID, ActualWaitingCount, DirectQueryCount]));
      
      // Assert: จำนวนคิวรอต้องไม่รวมคิวที่เรียกแล้ว (fstatus="1")
      Query.Close;
      Query.SQL.Text := 
        'SELECT COUNT(*) as queue_count ' +
        'FROM queue_data ' +
        'WHERE room = :room AND fstatus = ''1'' AND barcodes LIKE ''TEST_COUNT_%''';
      Query.ParamByName('room').AsInteger := RoomID;
      Query.Open;
      
      Assert.AreEqual(NumCalledQueues, Query.FieldByName('queue_count').AsInteger,
        Format('Iteration %d (Room %d): ต้องมีคิวที่เรียกแล้ว %d คิว',
        [i, RoomID, NumCalledQueues]));
      
      // ล้างข้อมูลทดสอบของ iteration นี้
      Query.Close;
      Query.SQL.Text := 
        'DELETE FROM queue_data ' +
        'WHERE room = :room AND barcodes LIKE ''TEST_COUNT_%''';
      Query.ParamByName('room').AsInteger := RoomID;
      Query.Execute;
    end;
    
    // ทดสอบกรณี edge case: ไม่มีคิวเลย
    ActualWaitingCount := FMainForm.GetWaitingQueueCount(1);
    Assert.AreEqual(0, ActualWaitingCount,
      'เมื่อไม่มีคิวเลย GetWaitingQueueCount ต้องคืนค่า 0');
    
    // ทดสอบกรณี edge case: มีแต่คิวที่เรียกแล้ว (fstatus="1")
    for j := 1 to 5 do
    begin
      TestBarcode := GenerateRandomBarcode;
      InsertTestQueue(TestBarcode, Format('%.4d', [j]), 1, '1');
    end;
    
    ActualWaitingCount := FMainForm.GetWaitingQueueCount(1);
    Assert.AreEqual(0, ActualWaitingCount,
      'เมื่อมีแต่คิวที่เรียกแล้ว GetWaitingQueueCount ต้องคืนค่า 0');
    
    // ทดสอบกรณี edge case: มีแต่คิวรอ (fstatus="2")
    Query.Close;
    Query.SQL.Text := 'DELETE FROM queue_data WHERE barcodes LIKE ''TEST_COUNT_%''';
    Query.Execute;
    
    for j := 1 to 7 do
    begin
      TestBarcode := GenerateRandomBarcode;
      InsertTestQueue(TestBarcode, Format('%.4d', [j]), 1, '2');
    end;
    
    ActualWaitingCount := FMainForm.GetWaitingQueueCount(1);
    Assert.AreEqual(7, ActualWaitingCount,
      'เมื่อมีคิวรอ 7 คิว GetWaitingQueueCount ต้องคืนค่า 7');
    
    // ทดสอบกรณี: แต่ละ room ต้องนับแยกกัน
    Query.Close;
    Query.SQL.Text := 'DELETE FROM queue_data WHERE barcodes LIKE ''TEST_COUNT_%''';
    Query.Execute;
    
    // สร้างคิวรอสำหรับแต่ละ room
    for RoomID := 1 to 4 do
    begin
      for j := 1 to RoomID * 2 do // room 1 = 2 คิว, room 2 = 4 คิว, room 3 = 6 คิว, room 4 = 8 คิว
      begin
        TestBarcode := GenerateRandomBarcode;
        
        case RoomID of
          1: QueueNumber := Format('%.4d', [j]);
          2: QueueNumber := Format('5%.3d', [j]);
          3: QueueNumber := Format('2%.3d', [j]);
          4: QueueNumber := Format('1%.3d', [j]);
        end;
        
        InsertTestQueue(TestBarcode, QueueNumber, RoomID, '2');
      end;
    end;
    
    // ตรวจสอบว่าแต่ละ room นับถูกต้อง
    Assert.AreEqual(2, FMainForm.GetWaitingQueueCount(1),
      'Room 1 ต้องมีคิวรอ 2 คิว');
    Assert.AreEqual(4, FMainForm.GetWaitingQueueCount(2),
      'Room 2 ต้องมีคิวรอ 4 คิว');
    Assert.AreEqual(6, FMainForm.GetWaitingQueueCount(3),
      'Room 3 ต้องมีคิวรอ 6 คิว');
    Assert.AreEqual(8, FMainForm.GetWaitingQueueCount(4),
      'Room 4 ต้องมีคิวรอ 8 คิว');
    
  finally
    Query.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TQueueCountTests);

end.
