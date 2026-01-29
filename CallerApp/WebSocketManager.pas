unit WebSocketManager;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.IniFiles, Winapi.Windows,
  sgcWebSocket, sgcWebSocket_Classes, sgcWebSocket_Server, Vcl.ExtCtrls,
  ErrorLogger, PerformanceMonitor;

type
  TConnectionStatusEvent = procedure(const Status: string; IsConnected: Boolean) of object;
  TErrorLogEvent = procedure(const ErrorMsg: string; const ErrorType: string) of object;

  TWebSocketManager = class
  private
    FServer: TsgcWebSocketServer;
    FPort: Integer;
    FAutoReconnect: Boolean;
    FReconnectInterval: Integer;
    FReconnectTimer: TTimer;
    FOnConnectionStatus: TConnectionStatusEvent;
    FOnErrorLog: TErrorLogEvent;
    FLastError: string;
    FConnectionAttempts: Integer;
    FMaxConnectionAttempts: Integer;
    
    procedure OnConnect(Connection: TsgcWSConnection);
    procedure OnDisconnect(Connection: TsgcWSConnection; Code: Integer);
    procedure OnMessage(Connection: TsgcWSConnection; const Text: string);
    procedure OnReconnectTimer(Sender: TObject);
    procedure LogError(const ErrorMsg: string; const ErrorType: string = 'WEBSOCKET');
    procedure UpdateConnectionStatus(const Status: string; IsConnected: Boolean);
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure LoadConfiguration(const ConfigFileName: string);
    function StartServer: Boolean;
    procedure StopServer;
    function IsServerActive: Boolean;
    procedure EnableAutoReconnect(Enabled: Boolean);
    function GetLastError: string;
    function GetConnectionAttempts: Integer;
    
    procedure SendQueueData(const QueueNumbers: TArray<string>; const IsNew: TArray<Boolean>);
    
    property Port: Integer read FPort write FPort;
    property AutoReconnect: Boolean read FAutoReconnect write FAutoReconnect;
    property ReconnectInterval: Integer read FReconnectInterval write FReconnectInterval;
    property OnConnectionStatus: TConnectionStatusEvent read FOnConnectionStatus write FOnConnectionStatus;
    property OnErrorLog: TErrorLogEvent read FOnErrorLog write FOnErrorLog;
  end;

implementation

constructor TWebSocketManager.Create;
begin
  inherited;
  FServer := TsgcWebSocketServer.Create(nil);
  FServer.OnConnect := OnConnect;
  FServer.OnDisconnect := OnDisconnect;
  FServer.OnMessage := OnMessage;
  
  // Initialize auto-reconnect settings
  FPort := 8080; // Default port
  FAutoReconnect := True;
  FReconnectInterval := 5000; // 5 seconds
  FConnectionAttempts := 0;
  FMaxConnectionAttempts := 10;
  
  // Create reconnect timer
  FReconnectTimer := TTimer.Create(nil);
  FReconnectTimer.Enabled := False;
  FReconnectTimer.OnTimer := OnReconnectTimer;
end;

destructor TWebSocketManager.Destroy;
begin
  StopServer;
  FReconnectTimer.Free;
  FServer.Free;
  inherited;
end;

procedure TWebSocketManager.LoadConfiguration(const ConfigFileName: string);
var  IniFile: TIniFile;
begin
  if FileExists(ConfigFileName) then
  begin
    IniFile := TIniFile.Create(ConfigFileName);
    try
      FPort               := IniFile.ReadInteger('WEBSOCKET', 'ServerPort', 8080);
      FAutoReconnect      := IniFile.ReadBool('WEBSOCKET', 'AutoReconnect', True);
      FReconnectInterval  := IniFile.ReadInteger('WEBSOCKET', 'ReconnectInterval', 5000);
      UpdateConnectionStatus('Configuration loaded', False);
    finally
      IniFile.Free;
    end;
  end
  else
  begin
    LogError('Configuration file not found: ' + ConfigFileName, 'CONFIG');
  end;
end;

function TWebSocketManager.StartServer: Boolean;
var
  PerfMonitor: TPerformanceMonitor;
  OriginalPort: Integer;
  PortTried: Integer;
begin
  Result := False;
  PerfMonitor := TPerformanceMonitor.Instance;
  PerfMonitor.StartOperation('WebSocket_StartServer');
  
  try
    if not FServer.Active then
    begin
      OriginalPort := FPort;
      PortTried := 0;
      
      // Try original port first, then try nearby ports if failed
      while (not Result) and (PortTried < 5) do
      begin
        try
          FServer.Port := FPort + PortTried;
          FServer.Active := True;
          Result := FServer.Active;
          
          if Result then
          begin
            FConnectionAttempts := 0;
            FLastError := '';
            if PortTried > 0 then
              UpdateConnectionStatus(Format('WebSocket Server started on port %d (original %d was busy)', [FPort + PortTried, OriginalPort]), True)
            else
              UpdateConnectionStatus(Format('WebSocket Server started on port %d', [FPort]), True);
            TErrorLogger.Instance.LogConnectionEvent('Server Started', Format('Port: %d', [FPort + PortTried]));
            PerfMonitor.EndOperation('WebSocket_StartServer', True);
            Break;
          end;
        except
          on E: Exception do
          begin
            FLastError := Format('Exception starting WebSocket Server: %s', [E.Message]);
            LogError(FLastError, 'STARTUP');
            Inc(PortTried);
            if PortTried >= 5 then
            begin
              PerfMonitor.EndOperation('WebSocket_StartServer', False, FLastError);
            end;
          end;
        end;
      end;
      
      if not Result then
      begin
        LogError(Format('Failed to start WebSocket Server on ports %d-%d', [OriginalPort, OriginalPort + 4]), 'STARTUP');
      end;
    end
    else
    begin
      Result := True;
      UpdateConnectionStatus('WebSocket Server already active', True);
      PerfMonitor.EndOperation('WebSocket_StartServer', True);
    end;
  except
    on E: Exception do
    begin
      FLastError := E.Message;
      LogError(Format('Exception starting WebSocket Server: %s', [E.Message]), 'EXCEPTION');
      TErrorLogger.Instance.LogException(E, 'Starting WebSocket Server', 'WEBSOCKET');
      PerfMonitor.EndOperation('WebSocket_StartServer', False, E.Message);
      
      // Try auto-reconnect if enabled
      if FAutoReconnect and (FConnectionAttempts < FMaxConnectionAttempts) then
      begin
        Inc(FConnectionAttempts);
        FReconnectTimer.Interval := FReconnectInterval;
        FReconnectTimer.Enabled := True;
        UpdateConnectionStatus(Format('Auto-reconnect attempt %d/%d scheduled', 
          [FConnectionAttempts, FMaxConnectionAttempts]), False);
      end;
      
      Result := False;
    end;
  end;
end;

procedure TWebSocketManager.StopServer;
begin
  try
    FReconnectTimer.Enabled := False;
    if FServer.Active then
    begin
      FServer.Active := False;
      UpdateConnectionStatus('WebSocket Server stopped', False);
    end;
  except
    on E: Exception do
    begin
      LogError(Format('Exception stopping WebSocket Server: %s', [E.Message]), 'EXCEPTION');
    end;
  end;
end;

function TWebSocketManager.IsServerActive: Boolean;
begin
  Result := FServer.Active;
end;

procedure TWebSocketManager.EnableAutoReconnect(Enabled: Boolean);
begin
  FAutoReconnect := Enabled;
  if not Enabled then
  begin
    FReconnectTimer.Enabled := False;
    FConnectionAttempts := 0;
  end;
end;

function TWebSocketManager.GetLastError: string;
begin
  Result := FLastError;
end;

function TWebSocketManager.GetConnectionAttempts: Integer;
begin
  Result := FConnectionAttempts;
end;

procedure TWebSocketManager.OnConnect(Connection: TsgcWSConnection);
begin
  UpdateConnectionStatus(Format('Terminal connected from %s', [Connection.IP]), True);
  FConnectionAttempts := 0; // Reset attempts on successful connection
end;

procedure TWebSocketManager.OnDisconnect(Connection: TsgcWSConnection; Code: Integer);
begin
  UpdateConnectionStatus(Format('Terminal disconnected (Code: %d)', [Code]), False);
  
  // Start auto-reconnect if enabled and server is still active
  if FAutoReconnect and FServer.Active and (FConnectionAttempts < FMaxConnectionAttempts) then
  begin
    Inc(FConnectionAttempts);
    FReconnectTimer.Interval := FReconnectInterval;
    FReconnectTimer.Enabled := True;
    UpdateConnectionStatus(Format('Auto-reconnect scheduled (attempt %d/%d)', 
      [FConnectionAttempts, FMaxConnectionAttempts]), False);
  end;
end;

procedure TWebSocketManager.OnMessage(Connection: TsgcWSConnection; const Text: string);
begin
  // Handle incoming messages from Terminal
  UpdateConnectionStatus('Message received from Terminal', True);
  // Log the message for debugging
  LogError(Format('Received message: %s', [Text]), 'MESSAGE');
end;

procedure TWebSocketManager.OnReconnectTimer(Sender: TObject);
begin
  FReconnectTimer.Enabled := False;
  
  if not FServer.Active then
  begin
    UpdateConnectionStatus(Format('Attempting reconnect %d/%d...', 
      [FConnectionAttempts, FMaxConnectionAttempts]), False);
    StartServer;
  end;
end;

procedure TWebSocketManager.LogError(const ErrorMsg: string; const ErrorType: string);
begin
  FLastError := ErrorMsg;
  
  // Call event handler if assigned
  if Assigned(FOnErrorLog) then
    FOnErrorLog(ErrorMsg, ErrorType);
    
  // Also log to system (could be enhanced to write to file)
  OutputDebugString(PChar(Format('[%s] %s: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), ErrorType, ErrorMsg])));
end;

procedure TWebSocketManager.UpdateConnectionStatus(const Status: string; IsConnected: Boolean);
begin
  if Assigned(FOnConnectionStatus) then
    FOnConnectionStatus(Status, IsConnected);
end;

procedure TWebSocketManager.SendQueueData(const QueueNumbers: TArray<string>; const IsNew: TArray<Boolean>);
var
  JsonObj: TJSONObject;
  DataObj: TJSONObject;
  QueueArray: TJSONArray;
  IsNewArray: TJSONArray;
  i: Integer;
  JsonString: string;
  PerfMonitor: TPerformanceMonitor;
begin
  if not IsServerActive then Exit;
  if Length(QueueNumbers) = 0 then Exit;
  
  PerfMonitor := TPerformanceMonitor.Instance;
  PerfMonitor.StartOperation('WebSocket_SendData');
  
  // Create JSON message according to design specification
  JsonObj := TJSONObject.Create;
  try
    JsonObj.AddPair('type', 'queue_call');
    JsonObj.AddPair('timestamp', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss"Z"', Now));
    
    DataObj := TJSONObject.Create;
    
    // Add queue numbers array
    QueueArray := TJSONArray.Create;
    for i := 0 to High(QueueNumbers) do
      QueueArray.AddElement(TJSONString.Create(QueueNumbers[i]));
    DataObj.AddPair('queue_numbers', QueueArray);
    
    // Add is_new array
    IsNewArray := TJSONArray.Create;
    for i := 0 to High(IsNew) do
      IsNewArray.AddElement(TJSONBool.Create(IsNew[i]));
    DataObj.AddPair('is_new', IsNewArray);
    
    DataObj.AddPair('caller_id', 'CALLER_01');
    JsonObj.AddPair('data', DataObj);
    
    JsonString := JsonObj.ToString;
    
    try
      // Send to all connected clients using broadcast method
      FServer.BroadCast(JsonString);
      
      // Log successful transmission
      TErrorLogger.Instance.LogMessage(
        Format('Sent queue data: %d queues to all clients', 
        [Length(QueueNumbers)]), 
        llInfo, 'WEBSOCKET');
        
      PerfMonitor.EndOperation('WebSocket_SendData', True);
      
    except
      on E: Exception do
      begin
        TErrorLogger.Instance.LogException(E, 'Broadcasting queue data', 'WEBSOCKET');
        PerfMonitor.EndOperation('WebSocket_SendData', False, E.Message);
        raise;
      end;
    end;
    
  finally
    JsonObj.Free;
  end;
end;

end.