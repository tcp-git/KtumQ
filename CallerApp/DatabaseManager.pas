unit DatabaseManager;

interface

uses
  System.SysUtils, System.Classes, System.IniFiles, Winapi.Windows,
  Uni, UniProvider, MySQLUniProvider;

type
  TConnectionStatusEvent = procedure(const Status: string; IsConnected: Boolean) of object;
  TErrorLogEvent = procedure(const ErrorMsg: string; const ErrorType: string) of object;

  TDatabaseManager = class
  private
    FConnection: TUniConnection;
    FQuery: TUniQuery;
    FConfigFile: string;
    FOnConnectionStatus: TConnectionStatusEvent;
    FOnErrorLog: TErrorLogEvent;
    FLastError: string;
    procedure LogError(const ErrorMsg: string; const ErrorType: string = 'DATABASE');
    procedure UpdateConnectionStatus(const Status: string; IsConnected: Boolean);
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure LoadConfiguration(const ConfigFileName: string);
    function Connect: Boolean;
    procedure Disconnect;
    function IsConnected: Boolean;
    function GetLastError: string;
    
    function CheckQueueHasData(const QueueNumber: string): Boolean;
    procedure UpdateQueueStatus(const QueueNumber: string; HasData: Boolean);
    procedure LogQueueHistory(const QueueNumbers: TArray<string>);
    
    property Connection: TUniConnection read FConnection;
    property OnConnectionStatus: TConnectionStatusEvent read FOnConnectionStatus write FOnConnectionStatus;
    property OnErrorLog: TErrorLogEvent read FOnErrorLog write FOnErrorLog;
  end;

implementation

constructor TDatabaseManager.Create;
begin
  inherited;
  FConnection := TUniConnection.Create(nil);
  FQuery := TUniQuery.Create(nil);
  FQuery.Connection := FConnection;
  
  // Set MySQL provider
  FConnection.ProviderName := 'MySQL';
end;

destructor TDatabaseManager.Destroy;
begin
  Disconnect;
  FQuery.Free;
  FConnection.Free;
  inherited;
end;

procedure TDatabaseManager.LoadConfiguration(const ConfigFileName: string);
var
  IniFile: TIniFile;
begin
  FConfigFile := ConfigFileName;
  
  if not FileExists(ConfigFileName) then
  begin
    LogError('Configuration file not found: ' + ConfigFileName, 'CONFIG');
    Exit;
  end;
    
  IniFile := TIniFile.Create(ConfigFileName);
  try
    FConnection.Server      := IniFile.ReadString('DATABASE', 'Server', 'localhost');
    FConnection.Port        := IniFile.ReadInteger('DATABASE', 'Port', 3307);
    FConnection.Database    := IniFile.ReadString('DATABASE', 'Database', 'queue_system');
    FConnection.Username    := IniFile.ReadString('DATABASE', 'Username', 'root');
    FConnection.Password    := IniFile.ReadString('DATABASE', 'Password', 'saas');
    FConnection.LoginPrompt := False;
    
    // Set connection timeout
    FConnection.SpecificOptions.Values['ConnectionTimeout'] := 
      IniFile.ReadString('DATABASE', 'ConnectionTimeout', '30');
      
    UpdateConnectionStatus('Configuration loaded', False);
  finally
    IniFile.Free;
  end;
end;

function TDatabaseManager.Connect: Boolean;
begin
  Result := False;
  try
    if not FConnection.Connected then
    begin
      UpdateConnectionStatus('Connecting to database...', False);
      FConnection.Connect;
      Result := FConnection.Connected;
      
      if Result then
      begin
        FLastError := '';
        UpdateConnectionStatus(Format('Connected to %s:%d/%s', 
          [FConnection.Server, FConnection.Port, FConnection.Database]), True);
      end
      else
      begin
        LogError('Failed to connect to database', 'CONNECTION');
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
      LogError(Format('Database connection exception: %s', [E.Message]), 'EXCEPTION');
      Result := False;
    end;
  end;
end;

procedure TDatabaseManager.Disconnect;
begin
  try
    if FConnection.Connected then
    begin
      FConnection.Disconnect;
      UpdateConnectionStatus('Disconnected from database', False);
    end;
  except
    on E: Exception do
    begin
      LogError(Format('Exception disconnecting from database: %s', [E.Message]), 'EXCEPTION');
    end;
  end;
end;

function TDatabaseManager.IsConnected: Boolean;
begin
  Result := FConnection.Connected;
end;

function TDatabaseManager.GetLastError: string;
begin
  Result := FLastError;
end;

procedure TDatabaseManager.LogError(const ErrorMsg: string; const ErrorType: string);
begin
  FLastError := ErrorMsg;
  
  // Call event handler if assigned
  if Assigned(FOnErrorLog) then
    FOnErrorLog(ErrorMsg, ErrorType);
    
  // Also log to system (could be enhanced to write to file)
  OutputDebugString(PChar(Format('[%s] %s: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), ErrorType, ErrorMsg])));
end;

procedure TDatabaseManager.UpdateConnectionStatus(const Status: string; IsConnected: Boolean);
begin
  if Assigned(FOnConnectionStatus) then
    FOnConnectionStatus(Status, IsConnected);
end;

function TDatabaseManager.CheckQueueHasData(const QueueNumber: string): Boolean;
begin
  Result := False;
  if not IsConnected then 
  begin
    LogError('Cannot check queue data - database not connected', 'QUERY');
    Exit;
  end;
  
  try
    FQuery.SQL.Text := 'SELECT has_data FROM queue_status WHERE queue_number = :queue_number';
    FQuery.ParamByName('queue_number').AsString := QueueNumber;
    FQuery.Open;
    
    if not FQuery.IsEmpty then
      Result := FQuery.FieldByName('has_data').AsBoolean;
      
    FQuery.Close;
  except
    on E: Exception do
    begin
      LogError(Format('Error checking queue %s: %s', [QueueNumber, E.Message]), 'QUERY');
      Result := False;
    end;
  end;
end;

procedure TDatabaseManager.UpdateQueueStatus(const QueueNumber: string; HasData: Boolean);
begin
  if not IsConnected then 
  begin
    LogError('Cannot update queue status - database not connected', 'UPDATE');
    Exit;
  end;
  
  try
    FQuery.SQL.Text := 'UPDATE queue_status SET has_data = :has_data, last_updated = NOW() WHERE queue_number = :queue_number';
    FQuery.ParamByName('has_data').AsBoolean := HasData;
    FQuery.ParamByName('queue_number').AsString := QueueNumber;
    FQuery.ExecSQL;
  except
    on E: Exception do
    begin
      LogError(Format('Error updating queue %s status: %s', [QueueNumber, E.Message]), 'UPDATE');
    end;
  end;
end;

procedure TDatabaseManager.LogQueueHistory(const QueueNumbers: TArray<string>);
var
  JsonArray: string;
  i: Integer;
begin
  if not IsConnected then 
  begin
    LogError('Cannot log queue history - database not connected', 'INSERT');
    Exit;
  end;
  
  if Length(QueueNumbers) = 0 then Exit;
  
  // Build JSON array string
  JsonArray := '[';
  for i := 0 to High(QueueNumbers) do
  begin
    if i > 0 then JsonArray := JsonArray + ',';
    JsonArray := JsonArray + '"' + QueueNumbers[i] + '"';
  end;
  JsonArray := JsonArray + ']';
  
  try
    FQuery.SQL.Text := 'INSERT INTO queue_history (queue_numbers, sent_at, sent_by, status) VALUES (:queue_numbers, NOW(), ''CALLER'', ''SENT'')';
    FQuery.ParamByName('queue_numbers').AsString := JsonArray;
    FQuery.ExecSQL;
  except
    on E: Exception do
    begin
      LogError(Format('Error logging queue history: %s', [E.Message]), 'INSERT');
    end;
  end;
end;

end.