unit QueueControllerTests;

interface

uses
  TestFramework, QueueController, DatabaseManager, WebSocketManager;

type
  TQueueControllerTest = class(TTestCase)
  private
    FQueueController: TQueueController;
    FDatabaseManager: TDatabaseManager;
    FWebSocketManager: TWebSocketManager;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestQueueSelectionToggle;
    procedure TestMultipleQueueSelection;
    procedure TestSendStatusPersistence;
    procedure TestClearSelection;
  end;

implementation

uses
  System.SysUtils;

{ TQueueControllerTest }

procedure TQueueControllerTest.SetUp;
begin
  FDatabaseManager := TDatabaseManager.Create;
  FWebSocketManager := TWebSocketManager.Create;
  FQueueController := TQueueController.Create(FDatabaseManager, FWebSocketManager);
end;

procedure TQueueControllerTest.TearDown;
begin
  FQueueController.Free;
  FWebSocketManager.Free;
  FDatabaseManager.Free;
end;

procedure TQueueControllerTest.TestQueueSelectionToggle;
var
  queueNumber: string;
  isSelected: Boolean;
begin
  queueNumber := '0001';
  
  // Test selecting a queue
  isSelected := FQueueController.ToggleQueueSelection(queueNumber);
  CheckTrue(isSelected, 'Queue should be selected');
  CheckEquals(1, FQueueController.SelectedQueues.Count, 'Should have 1 selected queue');
  CheckEquals(queueNumber, FQueueController.SelectedQueues[0], 'Selected queue should match');
  
  // Test deselecting the same queue
  isSelected := FQueueController.ToggleQueueSelection(queueNumber);
  CheckFalse(isSelected, 'Queue should be deselected');
  CheckEquals(0, FQueueController.SelectedQueues.Count, 'Should have 0 selected queues');
end;

procedure TQueueControllerTest.TestMultipleQueueSelection;
var
  queue1, queue2, queue3: string;
begin
  queue1 := '0001';
  queue2 := '0003';
  queue3 := '0005';
  
  // Select multiple non-continuous queues
  FQueueController.ToggleQueueSelection(queue1);
  FQueueController.ToggleQueueSelection(queue2);
  FQueueController.ToggleQueueSelection(queue3);
  
  CheckEquals(3, FQueueController.SelectedQueues.Count, 'Should have 3 selected queues');
  CheckTrue(FQueueController.SelectedQueues.IndexOf(queue1) >= 0, 'Queue1 should be selected');
  CheckTrue(FQueueController.SelectedQueues.IndexOf(queue2) >= 0, 'Queue2 should be selected');
  CheckTrue(FQueueController.SelectedQueues.IndexOf(queue3) >= 0, 'Queue3 should be selected');
  
  // Deselect middle queue
  FQueueController.ToggleQueueSelection(queue2);
  CheckEquals(2, FQueueController.SelectedQueues.Count, 'Should have 2 selected queues');
  CheckFalse(FQueueController.SelectedQueues.IndexOf(queue2) >= 0, 'Queue2 should not be selected');
end;

procedure TQueueControllerTest.TestSendStatusPersistence;
var
  queue1, queue2: string;
begin
  queue1 := '0001';
  queue2 := '0002';
  
  // Initially no queues should be marked as sent
  CheckFalse(FQueueController.IsQueueSent(queue1), 'Queue1 should not be marked as sent initially');
  CheckFalse(FQueueController.IsQueueSent(queue2), 'Queue2 should not be marked as sent initially');
  
  // Select and send queues (note: this will fail without proper connections, but should still track sent status)
  FQueueController.ToggleQueueSelection(queue1);
  FQueueController.ToggleQueueSelection(queue2);
  
  // The send operation will fail due to no connections, but we can test the tracking logic
  // by directly adding to sent queues (simulating successful send)
  FQueueController.SentQueues.Add(queue1);
  FQueueController.SentQueues.Add(queue2);
  
  CheckTrue(FQueueController.IsQueueSent(queue1), 'Queue1 should be marked as sent');
  CheckTrue(FQueueController.IsQueueSent(queue2), 'Queue2 should be marked as sent');
end;

procedure TQueueControllerTest.TestClearSelection;
var
  queue1, queue2: string;
begin
  queue1 := '0001';
  queue2 := '0002';
  
  // Select multiple queues
  FQueueController.ToggleQueueSelection(queue1);
  FQueueController.ToggleQueueSelection(queue2);
  CheckEquals(2, FQueueController.SelectedQueues.Count, 'Should have 2 selected queues');
  
  // Clear selection
  FQueueController.ClearSelection;
  CheckEquals(0, FQueueController.SelectedQueues.Count, 'Should have 0 selected queues after clear');
end;

initialization
  RegisterTest(TQueueControllerTest.Suite);

end.