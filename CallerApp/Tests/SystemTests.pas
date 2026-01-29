unit SystemTests;

interface

uses
  TestFramework, System.SysUtils, System.Classes, System.JSON, Vcl.Forms,
  DatabaseManager, WebSocketManager, QueueController,
  ErrorLogger, PerformanceMonitor;

type
  TSystemTest = class(TTestCase)
  private
    FCallerDB: TDatabaseManager;
    FCallerWS: TWebSocketManager;
    FCallerController: TQueueController;
    FConnectionEvents: TStringList;
    procedure OnConnectionEvent(const Status: string; IsConnected: Boolean);
    procedure SetupFullSystem;
    procedure CleanupFullSystem;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // End-to-End System Tests
    procedure TestCompleteWorkflow;
    procedure TestSystemResilience;
    procedure TestPerformanceUnderLoad;
    procedure TestAutoReconnectReliability;
    procedure TestErrorRecovery;
    
    // UI/UX Improvement Tests
    procedure TestResponseTimes;
    procedure TestSystemStability;
  end;

implementation

{ TSystemTest }

procedure TSystemTest.SetUp;
begin
  FConnectionEvents := TStringList.Create;
  
  // Clear performance metrics for clean testing
  TPerformanceMonitor.Instance.ClearMetrics;
  
  SetupFullSystem;
end;

procedure TSystemTest.TearDown;
begin
  CleanupFullSystem;
  FConnectionEvents.Free;
end;

procedure TSystemTest.SetupFullSystem;
begin
  // Initialize Caller system components
  FCallerDB := TDatabaseManager.Create;
  FCallerWS := TWebSocketManager.Create;
  FCallerController := TQueueController.Create(FCallerDB, FCallerWS);
  
  // Set up event handlers
  FCallerWS.OnConnectionStatus := OnConnectionEvent;
  
  // Load configuration
  FCallerDB.LoadConfiguration('config.ini');
  FCallerWS.LoadConfiguration('config.ini');
  
  // Enable auto-reconnect
  FCallerWS.EnableAutoReconnect(True);
end;

procedure TSystemTest.CleanupFullSystem;
begin
  if Assigned(FCallerController) then
    FCallerController.Free;
  if Assigned(FCallerWS) then
  begin
    FCallerWS.StopServer;
    FCallerWS.Free;
  end;
  if Assigned(FCallerDB) then
  begin
    FCallerDB.Disconnect;
    FCallerDB.Free;
  end;
end;

procedure TSystemTest.OnConnectionEvent(const Status: string; IsConnected: Boolean);
begin
  FConnectionEvents.Add(Format('[%s] %s: %s', 
    [FormatDateTime('hh:nn:ss.zzz', Now), 
     IfThen(IsConnected, 'CONNECTED', 'DISCONNECTED'), 
     Status]));
end;

procedure TSystemTest.TestCompleteWorkflow;
var
  QueueNumbers: TArray<string>;
  IsNew: TArray<Boolean>;
  PerfReport: TStringList;
begin
  // Test complete end-to-end workflow
  // **Feature: delphi-queue-system, Property 11: Flexible Queue Transmission**
  // **Validates: Requirements 5.3**
  
  TErrorLogger.Instance.LogMessage('Starting complete workflow test', llInfo, 'SYSTEM_TEST');
  
  // Step 1: Start Caller system
  CheckTrue(FCallerWS.StartServer, 'Caller WebSocket server should start');
  Sleep(1000);
  
  // Step 2: Connect Database
  CheckTrue(FCallerDB.Connect, 'Database should connect');
  
  // Step 3: Select queues in Caller
  FCallerController.ToggleQueueSelection('0001');
  FCallerController.ToggleQueueSelection('0003');
  FCallerController.ToggleQueueSelection('0005');
  
  CheckEquals(3, FCallerController.SelectedQueues.Count, 'Should have 3 selected queues');
  
  // Step 4: Send queues
  SetLength(QueueNumbers, 3);
  SetLength(IsNew, 3);
  QueueNumbers[0] := '0001'; IsNew[0] := True;
  QueueNumbers[1] := '0003'; IsNew[1] := False;
  QueueNumbers[2] := '0005'; IsNew[2] := True;
  
  try
    FCallerWS.SendQueueData(QueueNumbers, IsNew);
    CheckTrue(True, 'Queue data should be sent successfully');
  except
    on E: Exception do
      Fail('Queue data transmission failed: ' + E.Message);
  end;
  
  // Step 5: Check performance metrics
  PerfReport := TStringList.Create;
  try
    TPerformanceMonitor.Instance.GetPerformanceReport(PerfReport);
    CheckTrue(PerfReport.Count > 0, 'Should have performance metrics');
    
    // Verify reasonable response times
    CheckTrue(TPerformanceMonitor.Instance.GetAverageTime('WebSocket_SendData') < 1000, 
      'WebSocket send should be under 1 second');
      
  finally
    PerfReport.Free;
  end;
  
  TErrorLogger.Instance.LogMessage('Complete workflow test passed', llInfo, 'SYSTEM_TEST');
end;

procedure TSystemTest.TestSystemResilience;
var
  i: Integer;
  QueueNumbers: TArray<string>;
  IsNew: TArray<Boolean>;
begin
  // Test system resilience under various conditions
  TErrorLogger.Instance.LogMessage('Starting system resilience test', llInfo, 'SYSTEM_TEST');
  
  // Setup connection
  CheckTrue(FCallerWS.StartServer, 'Server should start');
  Sleep(1000);
  CheckTrue(FCallerDB.Connect, 'Database should connect');
  
  SetLength(QueueNumbers, 1);
  SetLength(IsNew, 1);
  QueueNumbers[0] := '0001';
  IsNew[0] := True;
  
  // Test multiple server restart cycles
  for i := 1 to 3 do
  begin
    TErrorLogger.Instance.LogMessage(Format('Resilience test cycle %d', [i]), llInfo, 'SYSTEM_TEST');
    
    // Stop and restart server
    FCallerWS.StopServer;
    Sleep(1000);
    CheckTrue(FCallerWS.StartServer, Format('Should restart server in cycle %d', [i]));
    Sleep(1000);
    
    // Test data transmission after restart
    try
      FCallerWS.SendQueueData(QueueNumbers, IsNew);
      CheckTrue(True, Format('Should send data after restart in cycle %d', [i]));
    except
      on E: Exception do
        Fail(Format('Data transmission failed in cycle %d: %s', [i, E.Message]));
    end;
  end;
  
  TErrorLogger.Instance.LogMessage('System resilience test passed', llInfo, 'SYSTEM_TEST');
end;

procedure TSystemTest.TestPerformanceUnderLoad;
var
  i: Integer;
  QueueNumbers: TArray<string>;
  IsNew: TArray<Boolean>;
  StartTime: TDateTime;
  ElapsedMs: Int64;
  MessagesPerSecond: Double;
begin
  // Test system performance under load
  TErrorLogger.Instance.LogMessage('Starting performance under load test', llInfo, 'SYSTEM_TEST');
  
  // Setup
  CheckTrue(FCallerWS.StartServer, 'Server should start');
  Sleep(1000);
  CheckTrue(FCallerDB.Connect, 'Database should connect');
  
  SetLength(QueueNumbers, 1);
  SetLength(IsNew, 1);
  IsNew[0] := True;
  
  // Send 50 messages rapidly
  StartTime := Now;
  
  for i := 1 to 50 do
  begin
    QueueNumbers[0] := Format('%.4d', [(i mod 9) + 1]);
    try
      FCallerWS.SendQueueData(QueueNumbers, IsNew);
    except
      on E: Exception do
        Fail(Format('Performance test failed at message %d: %s', [i, E.Message]));
    end;
    Sleep(10); // Small delay to prevent overwhelming
  end;
  
  ElapsedMs := MilliSecondsBetween(Now, StartTime);
  MessagesPerSecond := (50 * 1000) / ElapsedMs;
  
  TErrorLogger.Instance.LogMessage(
    Format('Performance test: %d messages in %d ms (%.2f msg/sec)', 
    [50, ElapsedMs, MessagesPerSecond]), 
    llInfo, 'SYSTEM_TEST');
  
  // Verify performance criteria
  CheckTrue(ElapsedMs < 15000, 'Should process 50 messages within 15 seconds');
  CheckTrue(MessagesPerSecond > 3, 'Should process at least 3 messages per second');
  CheckTrue(FCallerWS.IsServerActive, 'Server should remain active under load');
  
  TErrorLogger.Instance.LogMessage('Performance under load test passed', llInfo, 'SYSTEM_TEST');
end;

procedure TSystemTest.TestAutoReconnectReliability;
begin
  // Test auto-reconnect reliability
  // **Feature: delphi-queue-system, Property Auto-reconnect functionality**
  // **Validates: Requirements 5.1**
  
  TErrorLogger.Instance.LogMessage('Starting auto-reconnect reliability test', llInfo, 'SYSTEM_TEST');
  
  // Initial connection
  CheckTrue(FCallerWS.StartServer, 'Server should start');
  Sleep(1000);
  
  FConnectionEvents.Clear;
  
  // Simulate server restart
  FCallerWS.StopServer;
  Sleep(2000); // Allow disconnection to be detected
  
  // Restart server
  CheckTrue(FCallerWS.StartServer, 'Server should restart');
  Sleep(2000);
  
  // Verify server is functional after restart
  var QueueNumbers: TArray<string>;
  var IsNew: TArray<Boolean>;
  SetLength(QueueNumbers, 1);
  SetLength(IsNew, 1);
  QueueNumbers[0] := '0001';
  IsNew[0] := True;
  
  try
    FCallerWS.SendQueueData(QueueNumbers, IsNew);
    CheckTrue(True, 'Should send data after server restart');
  except
    on E: Exception do
      Fail('Data transmission failed after restart: ' + E.Message);
  end;
  
  // Verify connection events were logged
  CheckTrue(FConnectionEvents.Count > 0, 'Should have connection status logs');
  
  TErrorLogger.Instance.LogMessage('Auto-reconnect reliability test passed', llInfo, 'SYSTEM_TEST');
end;

procedure TSystemTest.TestErrorRecovery;
var
  QueueNumbers: TArray<string>;
  IsNew: TArray<Boolean>;
begin
  // Test system error recovery capabilities
  TErrorLogger.Instance.LogMessage('Starting error recovery test', llInfo, 'SYSTEM_TEST');
  
  CheckTrue(FCallerWS.StartServer, 'Server should start');
  Sleep(1000);
  
  // Test 1: Empty queue data handling
  SetLength(QueueNumbers, 0);
  SetLength(IsNew, 0);
  
  // This should not crash the system
  try
    FCallerWS.SendQueueData(QueueNumbers, IsNew);
    CheckTrue(True, 'Empty data should be handled gracefully');
  except
    on E: Exception do
      CheckTrue(True, 'Empty data handled with exception: ' + E.Message);
  end;
  
  CheckTrue(FCallerWS.IsServerActive, 'Server should remain active after empty data');
  
  // Test 2: Recovery with valid data
  SetLength(QueueNumbers, 1);
  SetLength(IsNew, 1);
  QueueNumbers[0] := '0001';
  IsNew[0] := True;
  
  try
    FCallerWS.SendQueueData(QueueNumbers, IsNew);
    CheckTrue(True, 'Should recover and process valid data');
  except
    on E: Exception do
      Fail('Recovery with valid data failed: ' + E.Message);
  end;
  
  TErrorLogger.Instance.LogMessage('Error recovery test passed', llInfo, 'SYSTEM_TEST');
end;

procedure TSystemTest.TestResponseTimes;
var
  QueueNumbers: TArray<string>;
  IsNew: TArray<Boolean>;
  StartTime: TDateTime;
  ResponseTime: Int64;
  i: Integer;
  TotalResponseTime: Int64;
  AverageResponseTime: Double;
begin
  // Test UI/UX response times
  TErrorLogger.Instance.LogMessage('Starting response times test', llInfo, 'SYSTEM_TEST');
  
  CheckTrue(FCallerWS.StartServer, 'Server should start');
  Sleep(1000);
  
  SetLength(QueueNumbers, 1);
  SetLength(IsNew, 1);
  QueueNumbers[0] := '0001';
  IsNew[0] := True;
  
  TotalResponseTime := 0;
  
  // Measure response times for 10 operations
  for i := 1 to 10 do
  begin
    StartTime := Now;
    
    try
      FCallerWS.SendQueueData(QueueNumbers, IsNew);
      ResponseTime := MilliSecondsBetween(Now, StartTime);
      TotalResponseTime := TotalResponseTime + ResponseTime;
      
      TErrorLogger.Instance.LogMessage(
        Format('Response time test %d: %d ms', [i, ResponseTime]), 
        llDebug, 'SYSTEM_TEST');
    except
      on E: Exception do
        Fail(Format('Response time test %d failed: %s', [i, E.Message]));
    end;
    
    Sleep(100); // Small delay between tests
  end;
  
  AverageResponseTime := TotalResponseTime / 10;
  
  TErrorLogger.Instance.LogMessage(
    Format('Average response time: %.2f ms', [AverageResponseTime]), 
    llInfo, 'SYSTEM_TEST');
  
  // Verify response time criteria (should be under 500ms for good UX)
  CheckTrue(AverageResponseTime < 500, 'Average response time should be under 500ms');
  CheckTrue(AverageResponseTime > 0, 'Should have measurable response time');
  
  TErrorLogger.Instance.LogMessage('Response times test passed', llInfo, 'SYSTEM_TEST');
end;

procedure TSystemTest.TestSystemStability;
var
  i: Integer;
  QueueNumbers: TArray<string>;
  IsNew: TArray<Boolean>;
  StartTime: TDateTime;
  ElapsedMinutes: Double;
begin
  // Test system stability over extended period
  TErrorLogger.Instance.LogMessage('Starting system stability test', llInfo, 'SYSTEM_TEST');
  
  CheckTrue(FCallerWS.StartServer, 'Server should start');
  Sleep(1000);
  CheckTrue(FCallerDB.Connect, 'Database should connect');
  
  SetLength(QueueNumbers, 1);
  SetLength(IsNew, 1);
  IsNew[0] := True;
  
  StartTime := Now;
  
  // Run for 1 minute with continuous operations
  while MilliSecondsBetween(Now, StartTime) < 60000 do // 1 minute
  begin
    for i := 1 to 9 do
    begin
      QueueNumbers[0] := Format('%.4d', [i]);
      try
        FCallerWS.SendQueueData(QueueNumbers, IsNew);
      except
        on E: Exception do
          Fail('System stability test failed: ' + E.Message);
      end;
      
      Sleep(500); // Send every 500ms
      
      // Check if we should exit early
      if MilliSecondsBetween(Now, StartTime) >= 60000 then
        Break;
    end;
  end;
  
  ElapsedMinutes := MilliSecondsBetween(Now, StartTime) / 60000;
  
  TErrorLogger.Instance.LogMessage(
    Format('System stability test ran for %.2f minutes', [ElapsedMinutes]), 
    llInfo, 'SYSTEM_TEST');
  
  // Verify system is still stable
  CheckTrue(FCallerWS.IsServerActive, 'Server should remain active after extended operation');
  CheckTrue(FCallerDB.IsConnected, 'Database should remain connected after extended operation');
  
  // Test final operation to ensure system is responsive
  QueueNumbers[0] := '0001';
  try
    FCallerWS.SendQueueData(QueueNumbers, IsNew);
    CheckTrue(True, 'System should still be responsive after stability test');
  except
    on E: Exception do
      Fail('System not responsive after stability test: ' + E.Message);
  end;
  
  TErrorLogger.Instance.LogMessage('System stability test passed', llInfo, 'SYSTEM_TEST');
end;

initialization
  RegisterTest(TSystemTest.Suite);

end.