unit WebSocketClientManager;

interface

uses
  System.SysUtils, System.Classes, System.IniFiles, Winapi.Windows,
  sgcWebSocket, sgcWebSocket_Classes, sgcWebSocket_Client, Vcl.ExtCtrls;

type
  TWebSocketMessageEvent = procedure(const JsonMessage: string) of object;
  TConnectionStatusEvent = procedure(const Status: string; IsConnected: Boolean) of object;
  TErrorLogEvent = procedure(const ErrorMsg: string; const ErrorType: string) of object;

  TWebSocketClientManager = class
  private
    FClient: TsgcWebSocketClient;
    FHost: string;
    FPort: Integer;
    FAutoReconnect: Boolean;
    FReconnectInterval: Integer;
    FReconnectTimer: TTimer;
    FOnMessage: TWebSocketMessageEvent;
    FOnConnectionStatus: TConnectionStatusEvent;
    FOnErrorLog: TErrorLogEvent;
    FLastError: string;
    FConnectionAttempts: Integer;
    FMaxConnectionAttempts: Integer;
    
    procedure OnConnect(Connection: TsgcWSConnection);
    procedure OnDisconnect(Connection: TsgcWSConnection; Code: Integer);
    procedure OnMessage(Connection: TsgcWSConnection; const Text: string);
    procedure OnError(Connection: TsgcWSConnection; const Error: string);
    procedure OnReconnectTimer(Sender: TObject);
    procedure LogError(const ErrorMsg: string; const ErrorType: string = 'WEBSOCKET');
    procedure UpdateConnectionStatus(const Status: string; IsConnected: Boolean);
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure LoadConfiguration(const ConfigFileName: string);
    function Connect: Boolean;
    procedure Disconnect;
    function IsConnected: Boolean;
    procedure EnableAutoReconnect(Enabled: Boolean);
    function GetLastError: string;
    function GetConnectionAttempts: Integer;
    
    procedure SendResponse(const ResponseJson: string);
    
    property Host: string read FHost write FHost;
    property Port: Integer read FPort write FPort;
    property AutoReconnect: Boolean read FAutoReconnect write FAutoReconnect;
    property OnMessageReceived: TWebSocketMessageEvent read FOnMessage write FOnMessage;
    property OnConnectionStatus: TConnectionStatusEvent read FOnConnectionStatus write FOnConnectionStatus;
    property OnErrorLog: TErrorLogEvent read FOnErrorLog write FOnErrorLog;
  end;

implementation

constructor TWebSocketClientManager.Create;
begin
  inherited;
  FClient := TsgcWebSocketClient.Create(nil);
  FClient.OnConnect := OnConnect;
  FClient.OnDisconnect := OnDisconnect;
  FClient.OnMessage := OnMessage;
  FClient.OnError := OnError;
  
  // Default values with auto-reconnect support
  FHost := 'localhost';
  FPort := 8080;
  FAutoReconnect := True;
  FReconnectInterval := 5000;
  FConnectionAttempts := 0;
  FMaxConnectionAttempts := 10;
  
  // Create reconnect timer
  FReconnectTimer := TTimer.Create(nil);
  FReconnectTimer.Enabled := False;
  FReconnectTimer.OnTimer := OnReconnectTimer;
end;

destructor TWebSocketClientManager.Destroy;
begin
  Disconnect;
  FReconnectTimer.Free;
  FClient.Free;
  inherited;
end;

procedure TWebSocketClientManager.LoadConfiguration(const ConfigFileName: string);
var
  IniFile: TIniFile;
begin
  if FileExists(ConfigFileName) then
  begin
    IniFile := TIniFile.Create(ConfigFileName);
    try
      FHost := IniFile.ReadString('WEBSOCKET', 'ClientHost', 'localhost');
      FPort := IniFile.ReadInteger('WEBSOCKET', 'ClientPort', 8080);
      FAutoReconnect := IniFile.ReadBool('WEBSOCKET', 'AutoReconnect', True);
      FReconnectInterval := IniFile.ReadInteger('WEBSOCKET', 'ReconnectInterval', 5000);
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

function TWebSocketClientManager.Connect: Boolean;
begin
  Result := False;
  try
    if not FClient.Active then
    begin
      FClient.Host := FHost;
      FClient.Port := FPort;
      FClient.Active := True;
      Result := FClient.Active;
      
      if Result then
      begin
        FConnectionAttempts := 0;
        FLastError := '';
        UpdateConnectionStatus(Format('Connected to %s:%d', [FHost, FPort]), True);
      end
      else
      begin
        LogError(Format('Failed to connect to %s:%d', [FHost, FPort]), 'CONNECTION');
      end;
    end
    else
    begin
      Result := True;
      UpdateConnectionStatus('Already connected', True);
    end;
  except
    on E: Exception do
    begin
      FLastError := E.Message;
      LogError(Format('Exception connecting to %s:%d - %s', [FHost, FPort, E.Message]), 'EXCEPTION');
      
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

procedure TWebSocketClientManager.Disconnect;
begin
  try
    FReconnectTimer.Enabled := False;
    if FClient.Active then
    begin
      FClient.Active := False;
      UpdateConnectionStatus('Disconnected', False);
    end;
  except
    on E: Exception do
    begin
      LogError(Format('Exception disconnecting: %s', [E.Message]), 'EXCEPTION');
    end;
  end;
end;

function TWebSocketClientManager.IsConnected: Boolean;
begin
  Result := FClient.Active;
end;

procedure TWebSocketClientManager.EnableAutoReconnect(Enabled: Boolean);
begin
  FAutoReconnect := Enabled;
  if not Enabled then
  begin
    FReconnectTimer.Enabled := False;
    FConnectionAttempts := 0;
  end;
end;

function TWebSocketClientManager.GetLastError: string;
begin
  Result := FLastError;
end;

function TWebSocketClientManager.GetConnectionAttempts: Integer;
begin
  Result := FConnectionAttempts;
end;

procedure TWebSocketClientManager.OnConnect(Connection: TsgcWSConnection);
begin
  UpdateConnectionStatus(Format('Connected to Caller at %s:%d', [FHost, FPort]), True);
  FConnectionAttempts := 0; // Reset attempts on successful connection
end;

procedure TWebSocketClientManager.OnDisconnect(Connection: TsgcWSConnection; Code: Integer);
begin
  UpdateConnectionStatus(Format('Disconnected from Caller (Code: %d)', [Code]), False);
  
  // Start auto-reconnect if enabled
  if FAutoReconnect and (FConnectionAttempts < FMaxConnectionAttempts) then
  begin
    Inc(FConnectionAttempts);
    FReconnectTimer.Interval := FReconnectInterval;
    FReconnectTimer.Enabled := True;
    UpdateConnectionStatus(Format('Auto-reconnect scheduled (attempt %d/%d)', 
      [FConnectionAttempts, FMaxConnectionAttempts]), False);
  end;
end;

procedure TWebSocketClientManager.OnMessage(Connection: TsgcWSConnection; const Text: string);
begin
  UpdateConnectionStatus('Message received from Caller', True);
  
  // Forward message to handler
  if Assigned(FOnMessage) then
    FOnMessage(Text);
end;

procedure TWebSocketClientManager.OnError(Connection: TsgcWSConnection; const Error: string);
begin
  LogError(Format('WebSocket error: %s', [Error]), 'WEBSOCKET_ERROR');
end;

procedure TWebSocketClientManager.OnReconnectTimer(Sender: TObject);
begin
  FReconnectTimer.Enabled := False;
  
  if not FClient.Active then
  begin
    UpdateConnectionStatus(Format('Attempting reconnect %d/%d...', 
      [FConnectionAttempts, FMaxConnectionAttempts]), False);
    Connect;
  end;
end;

procedure TWebSocketClientManager.LogError(const ErrorMsg: string; const ErrorType: string);
begin
  FLastError := ErrorMsg;
  
  // Call event handler if assigned
  if Assigned(FOnErrorLog) then
    FOnErrorLog(ErrorMsg, ErrorType);
    
  // Also log to system (could be enhanced to write to file)
  OutputDebugString(PChar(Format('[%s] %s: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), ErrorType, ErrorMsg])));
end;

procedure TWebSocketClientManager.UpdateConnectionStatus(const Status: string; IsConnected: Boolean);
begin
  if Assigned(FOnConnectionStatus) then
    FOnConnectionStatus(Status, IsConnected);
end;

procedure TWebSocketClientManager.SendResponse(const ResponseJson: string);
begin
  if IsConnected then
    FClient.WriteData(ResponseJson);
end;

end.