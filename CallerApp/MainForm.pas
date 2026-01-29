unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  DatabaseManager, WebSocketManager, QueueController, SettingsForm,
  ErrorLogger, PerformanceMonitor, JvAppInst;

type
  TfrmMain = class(TForm)
    pnlGrid: TPanel;
    pnlControls: TPanel;
    btnFirst: TButton;
    btnNext: TButton;
    btnPrev: TButton;
    btnLast: TButton;
    btnSend: TButton;
    btnSettings: TButton;
    StatusBar: TPanel;
    pnlStatus: TPanel;
    lblDBStatus: TLabel;
    lblWSStatus: TLabel;
    memoErrorLog: TMemo;
    JvAppInstances1: TJvAppInstances;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnFirstClick(Sender: TObject);
    procedure btnNextClick(Sender: TObject);
    procedure btnPrevClick(Sender: TObject);
    procedure btnLastClick(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
  private
    FQueuePanels: array[0..8] of TPanel;
    FDatabaseManager: TDatabaseManager;
    FWebSocketManager: TWebSocketManager;
    FQueueController: TQueueController;
    FStatusTimer: TTimer;
    procedure CreateQueueGrid;
    procedure UpdateQueueStatus;
    procedure UpdateNavigationHighlight;
    procedure OnQueuePanelClick(Sender: TObject);
    procedure UpdateSelectionStatus;
    procedure OnDatabaseStatus(const Status: string; IsConnected: Boolean);
    procedure OnWebSocketStatus(const Status: string; IsConnected: Boolean);
    procedure OnErrorLog(const ErrorMsg: string; const ErrorType: string);
    procedure LogMessage(const Message: string; const MessageType: string = 'INFO');
    procedure OnStatusTimer(Sender: TObject);
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  // Initialize managers
  FDatabaseManager := TDatabaseManager.Create;
  FWebSocketManager := TWebSocketManager.Create;
  FQueueController := TQueueController.Create(FDatabaseManager, FWebSocketManager);
  
  // Set up event handlers for status updates and error logging
  FDatabaseManager.OnConnectionStatus := OnDatabaseStatus;
  FDatabaseManager.OnErrorLog := OnErrorLog;
  FWebSocketManager.OnConnectionStatus := OnWebSocketStatus;
  FWebSocketManager.OnErrorLog := OnErrorLog;
  
  // Create UI
  CreateQueueGrid;
  
  // Enhanced UI setup for better UX
  Self.Caption := 'Queue System - Caller Application v1.0';
  Self.Position := poScreenCenter;
  
  // Improve status bar appearance
  StatusBar.Font.Style := [fsBold];
  StatusBar.Color := clInfoBk;
  
  // Improve error log appearance
  memoErrorLog.Font.Name := 'Consolas';
  memoErrorLog.Font.Size := 9;
  memoErrorLog.Color := clBlack;
  memoErrorLog.Font.Color := clLime;
  memoErrorLog.ScrollBars := ssVertical;
  
  // Improve button appearance
  btnSend.Font.Style := [fsBold];
  btnSend.Font.Size := 10;
  btnSettings.Font.Size := 9;
  
  // Load configuration and connect with auto-connect enabled
  LogMessage('Starting application...', 'SYSTEM');
  TErrorLogger.Instance.LogMessage('Caller Application starting', llInfo, 'CALLER');
  
  FDatabaseManager.LoadConfiguration('config.ini');
  FWebSocketManager.LoadConfiguration('config.ini');
  
  // Enable auto-reconnect features with enhanced monitoring
  FWebSocketManager.EnableAutoReconnect(True);
  
  // Connect to database and start WebSocket server with performance monitoring
  TPerformanceMonitor.Instance.StartOperation('Application_Startup');
  
  if FDatabaseManager.Connect then
    LogMessage('Database connected successfully', 'DATABASE')
  else
    LogMessage('Database connection failed: ' + FDatabaseManager.GetLastError, 'ERROR');
    
  if FWebSocketManager.StartServer then
    LogMessage('WebSocket server started successfully', 'WEBSOCKET')
  else
    LogMessage('WebSocket server failed to start: ' + FWebSocketManager.GetLastError, 'ERROR');
  
  TPerformanceMonitor.Instance.EndOperation('Application_Startup', True);
  
  // Update initial status
  UpdateQueueStatus;
  UpdateSelectionStatus;
  LogMessage('Application initialization completed', 'SYSTEM');
  TErrorLogger.Instance.LogMessage('Caller Application ready', llInfo, 'CALLER');
  
  // Set up periodic status updates for better user feedback
  FStatusTimer := TTimer.Create(Self);
  FStatusTimer.Interval := 5000; // Update every 5 seconds
  FStatusTimer.OnTimer := OnStatusTimer;
  FStatusTimer.Enabled := True;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FQueueController.Free;
  FWebSocketManager.Free;
  FDatabaseManager.Free;
end;

procedure TfrmMain.CreateQueueGrid;
var
  i, row, col: Integer;
  panel: TPanel;
begin
  // Create 3x3 grid of panels for queue numbers
  for i := 0 to 8 do
  begin
    row := i div 3;
    col := i mod 3;
    
    panel := TPanel.Create(Self);
    panel.Parent := pnlGrid;
    panel.Left := col * 120 + 10;
    panel.Top := row * 80 + 10;
    panel.Width := 110;
    panel.Height := 70;
    panel.Caption := Format('%.4d', [i + 1]);
    panel.Font.Size := 16;
    panel.Font.Style := [fsBold];
    panel.Tag := i + 1;
    panel.OnClick := OnQueuePanelClick;
    panel.BevelOuter := bvRaised;
    panel.Color := clBtnFace;
    
    FQueuePanels[i] := panel;
  end;
end;

procedure TfrmMain.UpdateQueueStatus;
var
  i: Integer;
  queueNumber: string;
begin
  if Assigned(FQueueController) then
  begin
    for i := 0 to 8 do
    begin
      queueNumber := Format('%.4d', [i + 1]);
      
      // Check if this queue is currently selected
      if FQueueController.SelectedQueues.IndexOf(queueNumber) >= 0 then
        FQueuePanels[i].Color := clFuchsia  // Keep purple for selected
      else if FQueueController.CheckQueueStatus(queueNumber) then
        FQueuePanels[i].Color := clLime  // Green for has data
      else
        FQueuePanels[i].Color := clRed;  // Red for no data
    end;
  end;
  
  // Update navigation highlight
  UpdateNavigationHighlight;
end;

procedure TfrmMain.UpdateNavigationHighlight;
var
  i: Integer;
  currentPos: Integer;
begin
  if not Assigned(FQueueController) then Exit;
  
  currentPos := FQueueController.CurrentPosition;
  
  for i := 0 to 8 do
  begin
    // Reset border style for all panels
    FQueuePanels[i].BevelOuter := bvRaised;
    FQueuePanels[i].BevelWidth := 1;
    
    // Highlight current position with thick border
    if (i + 1) = currentPos then
    begin
      FQueuePanels[i].BevelOuter := bvRaised;
      FQueuePanels[i].BevelWidth := 3;
    end;
  end;
end;

procedure TfrmMain.OnQueuePanelClick(Sender: TObject);
var
  panel: TPanel;
  queueNumber: string;
  panelIndex: Integer;
  isSelected: Boolean;
begin
  panel := TPanel(Sender);
  queueNumber := Format('%.4d', [panel.Tag]);
  panelIndex := panel.Tag - 1; // Convert to 0-based index
  
  // Update navigation position when clicking on a panel
  FQueueController.SetCurrentPosition(panel.Tag);
  
  // Toggle queue selection
  isSelected := FQueueController.ToggleQueueSelection(queueNumber);
  
  if isSelected then
  begin
    // Queue is now selected - show purple color
    panel.Color := clFuchsia;  // Purple for selected
  end
  else
  begin
    // Queue is deselected - restore original status color
    if FQueueController.CheckQueueStatus(queueNumber) then
      panel.Color := clLime  // Green for has data
    else
      panel.Color := clRed;  // Red for no data
  end;
    
  UpdateNavigationHighlight;
  UpdateSelectionStatus;
end;

procedure TfrmMain.btnFirstClick(Sender: TObject);
begin
  FQueueController.NavigateToFirst;
  UpdateNavigationHighlight;
end;

procedure TfrmMain.btnNextClick(Sender: TObject);
begin
  LogMessage('Next button clicked', 'UI');
  FQueueController.NavigateNext;
  UpdateNavigationHighlight;
  LogMessage(Format('Current position: %d', [FQueueController.CurrentPosition]), 'UI');
end;

procedure TfrmMain.btnPrevClick(Sender: TObject);
begin
  FQueueController.NavigatePrevious;
  UpdateNavigationHighlight;
end;

procedure TfrmMain.btnLastClick(Sender: TObject);
begin
  FQueueController.NavigateToLast;
  UpdateNavigationHighlight;
end;

procedure TfrmMain.btnSendClick(Sender: TObject);
var
  selectedCount: Integer;
  success: Boolean;
begin
  selectedCount := FQueueController.SelectedQueues.Count;
  
  if selectedCount = 0 then
  begin
    StatusBar.Caption := 'No queues selected to send';
    Exit;
  end;
  
  // Send selected queues
  success := FQueueController.SendSelectedQueues;
  
  if success then
  begin
    // Update status and refresh display
    StatusBar.Caption := Format('Sent %d queue(s) successfully', [selectedCount]);
    UpdateQueueStatus; // Refresh display after sending
    UpdateSelectionStatus; // Update selection status
  end
  else
  begin
    StatusBar.Caption := 'Failed to send queues - check connections';
  end;
end;

procedure TfrmMain.btnSettingsClick(Sender: TObject);
var
  SettingsForm: TfrmSettings;
begin
  SettingsForm := TfrmSettings.Create(Self, 'config.ini');
  try
    if SettingsForm.ShowModal = mrOK then
    begin
      LogMessage('Settings updated, reconnecting...', 'SYSTEM');
      
      // Disconnect current connections
      FDatabaseManager.Disconnect;
      FWebSocketManager.StopServer;
      
      // Reload configuration
      FDatabaseManager.LoadConfiguration('config.ini');
      FWebSocketManager.LoadConfiguration('config.ini');
      
      // Reconnect with new settings
      if FDatabaseManager.Connect then
        LogMessage('Database reconnected with new settings', 'DATABASE')
      else
        LogMessage('Database reconnection failed: ' + FDatabaseManager.GetLastError, 'ERROR');
        
      if FWebSocketManager.StartServer then
        LogMessage('WebSocket server restarted with new settings', 'WEBSOCKET')
      else
        LogMessage('WebSocket server restart failed: ' + FWebSocketManager.GetLastError, 'ERROR');

      // Update display
      UpdateQueueStatus;
    end;
  finally
    SettingsForm.Free;
  end;
end;

procedure TfrmMain.OnDatabaseStatus(const Status: string; IsConnected: Boolean);
begin
  lblDBStatus.Caption := 'DB: ' + Status;
  if IsConnected then
    lblDBStatus.Font.Color := clGreen
  else
    lblDBStatus.Font.Color := clRed;
end;

procedure TfrmMain.OnWebSocketStatus(const Status: string; IsConnected: Boolean);
begin
  lblWSStatus.Caption := 'WS: ' + Status;
  if IsConnected then
    lblWSStatus.Font.Color := clGreen
  else
    lblWSStatus.Font.Color := clRed;
end;

procedure TfrmMain.OnErrorLog(const ErrorMsg: string; const ErrorType: string);
begin
  LogMessage(ErrorMsg, ErrorType);
end;

procedure TfrmMain.LogMessage(const Message: string; const MessageType: string);
var
  LogEntry: string;
begin
  LogEntry := Format('[%s] %s: %s', [FormatDateTime('hh:nn:ss', Now), MessageType, Message]);
  
  // Add to memo (keep last 100 lines)
  memoErrorLog.Lines.Add(LogEntry);
  if memoErrorLog.Lines.Count > 100 then
    memoErrorLog.Lines.Delete(0);
    
  // Scroll to bottom
  memoErrorLog.SelStart := Length(memoErrorLog.Text);
  memoErrorLog.SelLength := 0;
  
  // Update main status bar for important messages
  if (MessageType = 'ERROR') or (MessageType = 'SYSTEM') then
    StatusBar.Caption := Message;
end;

procedure TfrmMain.UpdateSelectionStatus;
var
  i: Integer;
  selectedList: string;
begin
  if FQueueController.SelectedQueues.Count = 0 then
  begin
    StatusBar.Caption := 'Ready - No queues selected';
  end
  else
  begin
    selectedList := '';
    for i := 0 to FQueueController.SelectedQueues.Count - 1 do
    begin
      if i > 0 then selectedList := selectedList + ', ';
      selectedList := selectedList + FQueueController.SelectedQueues[i];
    end;
    StatusBar.Caption := Format('Selected (%d): %s', [FQueueController.SelectedQueues.Count, selectedList]);
  end;
end;

procedure TfrmMain.OnStatusTimer(Sender: TObject);
begin
  UpdateQueueStatus;
  // Show connection status
  if FWebSocketManager.IsServerActive then
    lblWSStatus.Caption := 'WS: Active'
  else
    lblWSStatus.Caption := 'WS: Inactive';
end;

end.