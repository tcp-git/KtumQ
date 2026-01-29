unit DisplayForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  WebSocketClientManager, DisplayController;

type
  TfrmDisplay = class(TForm)
    pnlHeader: TPanel;
    lblTitle: TLabel;
    pnlGrid: TPanel;
    pnlScrollingText: TPanel;
    lblScrollingText: TLabel;
    tmrBlink: TTimer;
    tmrScroll: TTimer;
    tmrStopBlink: TTimer;
    pnlStatus: TPanel;
    lblConnectionStatus: TLabel;
    memoErrorLog: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure tmrBlinkTimer(Sender: TObject);
    procedure tmrScrollTimer(Sender: TObject);
    procedure tmrStopBlinkTimer(Sender: TObject);
  private
    FQueueLabels: array[0..8] of TLabel;
    FWebSocketClientManager: TWebSocketClientManager;
    FDisplayController: TDisplayController;
    FBlinkStartTime: TDateTime;
    procedure CreateQueueGrid;
    procedure OnWebSocketMessage(const JsonMessage: string);
    procedure OnConnectionStatus(const Status: string; IsConnected: Boolean);
    procedure OnErrorLog(const ErrorMsg: string; const ErrorType: string);
    procedure StopBlinkingForAllNumbers;
    procedure LogMessage(const Message: string; const MessageType: string = 'INFO');
  public
    procedure UpdateDisplay(const QueueNumbers: TArray<string>; const IsNew: TArray<Boolean>);
    property WebSocketClientManager: TWebSocketClientManager read FWebSocketClientManager;
  end;

var
  frmDisplay: TfrmDisplay;

implementation

{$R *.dfm}

procedure TfrmDisplay.FormCreate(Sender: TObject);
begin
  // Initialize managers
  FWebSocketClientManager := TWebSocketClientManager.Create;
  FDisplayController := TDisplayController.Create(Self);
  
  // Set up WebSocket event handlers
  FWebSocketClientManager.OnMessageReceived := OnWebSocketMessage;
  FWebSocketClientManager.OnConnectionStatus := OnConnectionStatus;
  FWebSocketClientManager.OnErrorLog := OnErrorLog;
  
  // Create UI
  CreateQueueGrid;
  
  // Load configuration and connect with auto-reconnect
  LogMessage('Starting Terminal Application...', 'SYSTEM');
  FWebSocketClientManager.LoadConfiguration('config.ini');
  FWebSocketClientManager.EnableAutoReconnect(True);
  
  if FWebSocketClientManager.Connect then
    LogMessage('WebSocket connected successfully', 'WEBSOCKET')
  else
    LogMessage('WebSocket connection failed: ' + FWebSocketClientManager.GetLastError, 'ERROR');
  
  // Set up timers
  tmrBlink.Interval := 500; // 500ms blink interval
  tmrBlink.Enabled := True;
  
  tmrScroll.Interval := 100; // 100ms scroll interval
  tmrScroll.Enabled := True;
  
  tmrStopBlink.Interval := 3000; // 3 seconds blink duration
  tmrStopBlink.Enabled := False; // Only enable when needed
  
  // Set up form
  Self.WindowState := wsMaximized;
  Self.Color := clBlack;
  lblTitle.Caption := 'ระบบแสดงผลคิว - Queue Display System';
  lblTitle.Font.Size := 24;
  lblTitle.Font.Color := clWhite;
  lblScrollingText.Caption := 'ยินดีต้อนรับสู่ระบบคิว - Welcome to Queue System';
  
  FBlinkStartTime := 0;
  LogMessage('Terminal Application initialization completed', 'SYSTEM');
end;

procedure TfrmDisplay.FormDestroy(Sender: TObject);
begin
  FDisplayController.Free;
  FWebSocketClientManager.Free;
end;

procedure TfrmDisplay.CreateQueueGrid;
var
  i, row, col: Integer;
  lbl: TLabel;
begin
  // Create 3x3 grid of labels for queue numbers
  for i := 0 to 8 do
  begin
    row := i div 3;
    col := i mod 3;
    
    lbl := TLabel.Create(Self);
    lbl.Parent := pnlGrid;
    lbl.Left := col * 200 + 20;
    lbl.Top := row * 120 + 20;
    lbl.Width := 180;
    lbl.Height := 100;
    lbl.Caption := '';
    lbl.Font.Size := 48;
    lbl.Font.Style := [fsBold];
    lbl.Font.Color := clWhite;
    lbl.Alignment := taCenter;
    lbl.Layout := tlCenter;
    lbl.Color := clBlack;
    lbl.Transparent := False;
    lbl.Tag := i;
    
    FQueueLabels[i] := lbl;
  end;
end;

procedure TfrmDisplay.OnWebSocketMessage(const JsonMessage: string);
begin
  if Assigned(FDisplayController) then
    FDisplayController.ProcessMessage(JsonMessage);
end;

procedure TfrmDisplay.UpdateDisplay(const QueueNumbers: TArray<string>; const IsNew: TArray<Boolean>);
var
  i: Integer;
  HasNewNumbers: Boolean;
begin
  HasNewNumbers := False;
  
  // Clear all labels first
  for i := 0 to 8 do
  begin
    FQueueLabels[i].Caption := '';
    FQueueLabels[i].Tag := FQueueLabels[i].Tag and $0FFF; // Clear blink flag
    FQueueLabels[i].Font.Color := clWhite; // Reset to default color
  end;
    
  // Update with new queue numbers
  for i := 0 to Min(High(QueueNumbers), 8) do
  begin
    if QueueNumbers[i] <> '' then
    begin
      FQueueLabels[i].Caption := QueueNumbers[i];
      
      // Check if this is a new number (should blink)
      if (i <= High(IsNew)) and IsNew[i] then
      begin
        // Mark as blinking for new numbers
        FQueueLabels[i].Tag := FQueueLabels[i].Tag or $1000; // Set blink flag
        FQueueLabels[i].Font.Color := clYellow; // Start with yellow for new numbers
        HasNewNumbers := True;
      end
      else
      begin
        // Steady display for old numbers
        FQueueLabels[i].Tag := FQueueLabels[i].Tag and $0FFF; // Clear blink flag
        FQueueLabels[i].Font.Color := clWhite; // White for old numbers
      end;
    end;
  end;
  
  // Start the stop-blink timer if there are new numbers
  if HasNewNumbers then
  begin
    FBlinkStartTime := Now;
    tmrStopBlink.Enabled := False; // Reset timer
    tmrStopBlink.Enabled := True;  // Start timer
  end;
end;

procedure TfrmDisplay.tmrBlinkTimer(Sender: TObject);
var
  i: Integer;
begin
  // Handle blinking for new numbers
  for i := 0 to 8 do
  begin
    // Check if this label should blink (has blink flag set)
    if (FQueueLabels[i].Tag and $1000) <> 0 then // Check blink flag
    begin
      // Only blink if there's actually a number to display
      if FQueueLabels[i].Caption <> '' then
      begin
        if FQueueLabels[i].Font.Color = clWhite then
          FQueueLabels[i].Font.Color := clYellow
        else
          FQueueLabels[i].Font.Color := clWhite;
      end;
    end;
  end;
end;

procedure TfrmDisplay.tmrScrollTimer(Sender: TObject);
var
  Text: string;
  ScrollSpeed: Integer;
begin
  // Enhanced scrolling text implementation
  Text := lblScrollingText.Caption;
  ScrollSpeed := 1; // Number of characters to scroll per timer tick
  
  if Length(Text) > ScrollSpeed then
  begin
    // Move characters from beginning to end
    lblScrollingText.Caption := Copy(Text, ScrollSpeed + 1, Length(Text) - ScrollSpeed) + 
                               Copy(Text, 1, ScrollSpeed);
  end
  else if Length(Text) > 0 then
  begin
    // For very short text, just move one character
    lblScrollingText.Caption := Copy(Text, 2, Length(Text) - 1) + Text[1];
  end;
end;

procedure TfrmDisplay.tmrStopBlinkTimer(Sender: TObject);
begin
  // Stop blinking after 3 seconds
  StopBlinkingForAllNumbers;
  tmrStopBlink.Enabled := False;
end;

procedure TfrmDisplay.OnConnectionStatus(const Status: string; IsConnected: Boolean);
begin
  lblConnectionStatus.Caption := 'Connection: ' + Status;
  if IsConnected then
    lblConnectionStatus.Font.Color := clGreen
  else
    lblConnectionStatus.Font.Color := clRed;
end;

procedure TfrmDisplay.OnErrorLog(const ErrorMsg: string; const ErrorType: string);
begin
  LogMessage(ErrorMsg, ErrorType);
end;

procedure TfrmDisplay.LogMessage(const Message: string; const MessageType: string);
var
  LogEntry: string;
begin
  LogEntry := Format('[%s] %s: %s', [FormatDateTime('hh:nn:ss', Now), MessageType, Message]);
  
  // Add to memo (keep last 50 lines for terminal)
  memoErrorLog.Lines.Add(LogEntry);
  if memoErrorLog.Lines.Count > 50 then
    memoErrorLog.Lines.Delete(0);
    
  // Scroll to bottom
  memoErrorLog.SelStart := Length(memoErrorLog.Text);
  memoErrorLog.SelLength := 0;
end;
procedure TfrmDisplay.StopBlinkingForAllNumbers;
var
  i: Integer;
begin
  // Stop blinking for all numbers and set them to steady white
  for i := 0 to 8 do
  begin
    if (FQueueLabels[i].Tag and $1000) <> 0 then // If it was blinking
    begin
      FQueueLabels[i].Tag := FQueueLabels[i].Tag and $0FFF; // Clear blink flag
      FQueueLabels[i].Font.Color := clWhite; // Set to steady white
    end;
  end;
end;

end.