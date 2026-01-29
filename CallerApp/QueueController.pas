unit QueueController;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  DatabaseManager, WebSocketManager, ErrorLogger;

type
  TQueueController = class
  private
    FDatabaseManager: TDatabaseManager;
    FWebSocketManager: TWebSocketManager;
    FSelectedQueues: TList<string>;
    FCurrentPosition: Integer;
    FSentQueues: TList<string>;
  public
    constructor Create(DatabaseManager: TDatabaseManager; WebSocketManager: TWebSocketManager);
    destructor Destroy; override;
    
    // Navigation methods
    procedure NavigateToFirst;
    procedure NavigateNext;
    procedure NavigatePrevious;
    procedure NavigateToLast;
    procedure SetCurrentPosition(Position: Integer);
    
    // Queue management
    function CheckQueueStatus(const QueueNumber: string): Boolean;
    function ToggleQueueSelection(const QueueNumber: string): Boolean;
    procedure ClearSelection;
    function SendSelectedQueues: Boolean;
    function IsQueueSent(const QueueNumber: string): Boolean;
    
    // Properties
    property CurrentPosition: Integer read FCurrentPosition;
    property SelectedQueues: TList<string> read FSelectedQueues;
    property SentQueues: TList<string> read FSentQueues;
  end;

implementation

constructor TQueueController.Create(DatabaseManager: TDatabaseManager; WebSocketManager: TWebSocketManager);
begin
  inherited Create;
  FDatabaseManager := DatabaseManager;
  FWebSocketManager := WebSocketManager;
  FSelectedQueues := TList<string>.Create;
  FSentQueues := TList<string>.Create;
  FCurrentPosition := 1; // Start at queue 0001
end;

destructor TQueueController.Destroy;
begin
  FSentQueues.Free;
  FSelectedQueues.Free;
  inherited;
end;

procedure TQueueController.NavigateToFirst;
begin
  FCurrentPosition := 1;
end;

procedure TQueueController.NavigateNext;
begin
  if FCurrentPosition < 9 then
    Inc(FCurrentPosition)
  else
    FCurrentPosition := 1; // Wrap around to first position
    
  // Debug: Log navigation
  TErrorLogger.Instance.LogMessage(
    Format('Navigate Next: Position now %d', [FCurrentPosition]), 
    llDebug, 'NAVIGATION');
end;

procedure TQueueController.NavigatePrevious;
begin
  if FCurrentPosition > 1 then
    Dec(FCurrentPosition)
  else
    FCurrentPosition := 9; // Wrap around to last position
    
  // Debug: Log navigation
  TErrorLogger.Instance.LogMessage(
    Format('Navigate Previous: Position now %d', [FCurrentPosition]), 
    llDebug, 'NAVIGATION');
end;

procedure TQueueController.NavigateToLast;
begin
  FCurrentPosition := 9;
end;

procedure TQueueController.SetCurrentPosition(Position: Integer);
begin
  if (Position >= 1) and (Position <= 9) then
    FCurrentPosition := Position;
end;

function TQueueController.CheckQueueStatus(const QueueNumber: string): Boolean;
begin
  Result := False;
  if Assigned(FDatabaseManager) and FDatabaseManager.IsConnected then
    Result := FDatabaseManager.CheckQueueHasData(QueueNumber);
end;

function TQueueController.ToggleQueueSelection(const QueueNumber: string): Boolean;
var
  Index: Integer;
begin
  Index := FSelectedQueues.IndexOf(QueueNumber);
  if Index >= 0 then
  begin
    // Remove from selection
    FSelectedQueues.Delete(Index);
    Result := False;
  end
  else
  begin
    // Add to selection
    FSelectedQueues.Add(QueueNumber);
    Result := True;
  end;
end;

procedure TQueueController.ClearSelection;
begin
  FSelectedQueues.Clear;
end;

function TQueueController.SendSelectedQueues: Boolean;
var
  QueueNumbers: TArray<string>;
  IsNew: TArray<Boolean>;
  i: Integer;
begin
  Result := False;
  if FSelectedQueues.Count = 0 then Exit;
  
  // Convert list to arrays
  SetLength(QueueNumbers, FSelectedQueues.Count);
  SetLength(IsNew, FSelectedQueues.Count);
  
  for i := 0 to FSelectedQueues.Count - 1 do
  begin
    QueueNumbers[i] := FSelectedQueues[i];
    // Check if this queue was sent before
    IsNew[i] := FSentQueues.IndexOf(FSelectedQueues[i]) < 0;
    
    // Add to sent queues if new
    if IsNew[i] then
      FSentQueues.Add(FSelectedQueues[i]);
  end;
  
  try
    // Send via WebSocket
    if Assigned(FWebSocketManager) and FWebSocketManager.IsServerActive then
      FWebSocketManager.SendQueueData(QueueNumbers, IsNew)
    else
      Exit;
      
    // Log to database
    if Assigned(FDatabaseManager) and FDatabaseManager.IsConnected then
      FDatabaseManager.LogQueueHistory(QueueNumbers)
    else
      Exit;
      
    // Clear selection after successful sending
    ClearSelection;
    Result := True;
      
  except
    on E: Exception do
    begin
      // Log error but don't clear selection if sending failed
      Result := False;
    end;
  end;
end;

function TQueueController.IsQueueSent(const QueueNumber: string): Boolean;
begin
  Result := FSentQueues.IndexOf(QueueNumber) >= 0;
end;

end.