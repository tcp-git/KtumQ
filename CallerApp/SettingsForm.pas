unit SettingsForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  System.IniFiles;

type
  TfrmSettings = class(TForm)
    pnlMain: TPanel;
    gbDatabase: TGroupBox;
    lblServer: TLabel;
    lblPort: TLabel;
    lblDatabase: TLabel;
    lblUsername: TLabel;
    lblPassword: TLabel;
    lblTimeout: TLabel;
    edtServer: TEdit;
    edtPort: TEdit;
    edtDatabase: TEdit;
    edtUsername: TEdit;
    edtPassword: TEdit;
    edtTimeout: TEdit;
    gbWebSocket: TGroupBox;
    lblServerIP: TLabel;
    lblServerPort: TLabel;
    lblAutoReconnect: TLabel;
    lblReconnectInterval: TLabel;
    edtServerIP: TEdit;
    edtServerPort: TEdit;
    chkAutoReconnect: TCheckBox;
    edtReconnectInterval: TEdit;
    pnlButtons: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    btnTestDB: TButton;
    btnTestWS: TButton;
    btnReset: TButton;
    lblStatus: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnTestDBClick(Sender: TObject);
    procedure btnTestWSClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
  private
    FConfigFileName: string;
    procedure LoadSettings;
    procedure SaveSettings;
    procedure ResetToDefaults;
    procedure UpdateStatus(const Message: string; IsError: Boolean = False);
    function ValidateSettings: Boolean;
  public
    constructor Create(AOwner: TComponent; const ConfigFileName: string); reintroduce;
  end;

var
  frmSettings: TfrmSettings;

implementation

uses
  DatabaseManager, WebSocketManager;

{$R *.dfm}

constructor TfrmSettings.Create(AOwner: TComponent; const ConfigFileName: string);
begin
  inherited Create(AOwner);
  FConfigFileName := ConfigFileName;
end;

procedure TfrmSettings.FormCreate(Sender: TObject);
begin
  LoadSettings;
  UpdateStatus('Settings loaded');
end;

procedure TfrmSettings.LoadSettings;
var
  IniFile: TIniFile;
begin
  if FileExists(FConfigFileName) then
  begin
    IniFile := TIniFile.Create(FConfigFileName);
    try
      // Database settings
      edtServer.Text    := IniFile.ReadString('DATABASE', 'Server', 'localhost');
      edtPort.Text      := IntToStr(IniFile.ReadInteger('DATABASE', 'Port', 3307));
      edtDatabase.Text  := IniFile.ReadString('DATABASE', 'Database', 'queue_system');
      edtUsername.Text  := IniFile.ReadString('DATABASE', 'Username', 'root');
      edtPassword.Text  := IniFile.ReadString('DATABASE', 'Password', 'saas');
      edtTimeout.Text   := IntToStr(IniFile.ReadInteger('DATABASE', 'ConnectionTimeout', 30));
      
      // WebSocket settings
      edtServerIP.Text          := IniFile.ReadString('WEBSOCKET', 'ServerIP', '0.0.0.0');
      edtServerPort.Text        := IntToStr(IniFile.ReadInteger('WEBSOCKET', 'ServerPort', 8081));
      chkAutoReconnect.Checked  := IniFile.ReadBool('WEBSOCKET', 'AutoReconnect', True);
      edtReconnectInterval.Text := IntToStr(IniFile.ReadInteger('WEBSOCKET', 'ReconnectInterval', 5000));
    finally
      IniFile.Free;
    end;
  end
  else
  begin
    ResetToDefaults;
  end;
end;

procedure TfrmSettings.SaveSettings;
var 
  IniFile: TIniFile;
  RetryCount: Integer;
begin
  if not ValidateSettings then
    Exit;

  RetryCount := 0;
  while RetryCount < 3 do
  begin
    try
      IniFile := TIniFile.Create(FConfigFileName);
      try
        // Database settings
        IniFile.WriteString('DATABASE', 'Server', edtServer.Text);
        IniFile.WriteInteger('DATABASE', 'Port', StrToIntDef(edtPort.Text, 3307));
        IniFile.WriteString('DATABASE', 'Database', edtDatabase.Text);
        IniFile.WriteString('DATABASE', 'Username', edtUsername.Text);
        IniFile.WriteString('DATABASE', 'Password', edtPassword.Text);
        IniFile.WriteInteger('DATABASE', 'ConnectionTimeout', StrToIntDef(edtTimeout.Text, 30));
        
        // WebSocket settings
        IniFile.WriteString('WEBSOCKET', 'ServerIP', edtServerIP.Text);
        IniFile.WriteInteger('WEBSOCKET', 'ServerPort', StrToIntDef(edtServerPort.Text, 8081));
        IniFile.WriteBool('WEBSOCKET', 'AutoReconnect', chkAutoReconnect.Checked);
        IniFile.WriteInteger('WEBSOCKET', 'ReconnectInterval', StrToIntDef(edtReconnectInterval.Text, 5000));
        
        UpdateStatus('Settings saved successfully');
        Exit; // Success, exit retry loop
      finally
        IniFile.Free;
      end;
    except
      on E: Exception do
      begin
        Inc(RetryCount);
        if RetryCount >= 3 then
          UpdateStatus('Unable to save settings after 3 attempts: ' + E.Message, True)
        else
        begin
          UpdateStatus(Format('Save attempt %d failed, retrying...', [RetryCount]));
          Sleep(500); // Wait before retry
        end;
      end;
    end;
  end;
end;

procedure TfrmSettings.ResetToDefaults;
begin
  // Database defaults
  edtServer.Text    := 'localhost';
  edtPort.Text      := '3307';
  edtDatabase.Text  := 'queue_system';
  edtUsername.Text  := 'root';
  edtPassword.Text  := 'saas';
  edtTimeout.Text   := '30';
  
  // WebSocket defaults
  edtServerIP.Text := '0.0.0.0';
  edtServerPort.Text := '8081';
  chkAutoReconnect.Checked := True;
  edtReconnectInterval.Text := '5000';
  
  UpdateStatus('Settings reset to defaults');
end;

procedure TfrmSettings.UpdateStatus(const Message: string; IsError: Boolean);
begin
  lblStatus.Caption := Message;
  if IsError then
    lblStatus.Font.Color := clRed
  else
    lblStatus.Font.Color := clGreen;
    
  Application.ProcessMessages;
end;

function TfrmSettings.ValidateSettings: Boolean;
begin
  Result := True;
  
  // Validate required fields
  if Trim(edtServer.Text) = '' then
  begin
    UpdateStatus('Server address is required', True);
    edtServer.SetFocus;
    Result := False;
    Exit;
  end;
  
  if Trim(edtDatabase.Text) = '' then
  begin
    UpdateStatus('Database name is required', True);
    edtDatabase.SetFocus;
    Result := False;
    Exit;
  end;
  
  if Trim(edtUsername.Text) = '' then
  begin
    UpdateStatus('Username is required', True);
    edtUsername.SetFocus;
    Result := False;
    Exit;
  end;
  
  // Validate numeric fields
  if StrToIntDef(edtPort.Text, -1) <= 0 then
  begin
    UpdateStatus('Invalid database port number', True);
    edtPort.SetFocus;
    Result := False;
    Exit;
  end;
  
  if StrToIntDef(edtServerPort.Text, -1) <= 0 then
  begin
    UpdateStatus('Invalid WebSocket server port number', True);
    edtServerPort.SetFocus;
    Result := False;
    Exit;
  end;
  
  if StrToIntDef(edtTimeout.Text, -1) <= 0 then
  begin
    UpdateStatus('Invalid connection timeout value', True);
    edtTimeout.SetFocus;
    Result := False;
    Exit;
  end;
  
  if StrToIntDef(edtReconnectInterval.Text, -1) <= 0 then
  begin
    UpdateStatus('Invalid reconnect interval value', True);
    edtReconnectInterval.SetFocus;
    Result := False;
    Exit;
  end;
end;

procedure TfrmSettings.btnOKClick(Sender: TObject);
begin
  SaveSettings;
  ModalResult := mrOK;
end;

procedure TfrmSettings.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmSettings.btnTestDBClick(Sender: TObject);
var
  TestDB: TDatabaseManager;
begin
  if not ValidateSettings then
    Exit;
    
  UpdateStatus('Testing database connection...');
  
  // Test connection using current config.ini
  TestDB := TDatabaseManager.Create;
  try
    TestDB.LoadConfiguration(FConfigFileName);
    if TestDB.Connect then
    begin
      UpdateStatus('Database connection successful!');
      TestDB.Disconnect;
    end
    else
    begin
      UpdateStatus('Database connection failed: ' + TestDB.GetLastError, True);
    end;
  finally
    TestDB.Free;
  end;
end;

procedure TfrmSettings.btnTestWSClick(Sender: TObject);
var
  TestWS: TWebSocketManager;
begin
  if not ValidateSettings then
    Exit;
    
  UpdateStatus('Testing WebSocket server...');


  // Test WebSocket using current config.ini
  TestWS := TWebSocketManager.Create;
  try
    TestWS.LoadConfiguration(FConfigFileName);
    if TestWS.StartServer then
    begin
      UpdateStatus('WebSocket server started successfully!');
      Sleep(1000); // Give it a moment
      TestWS.StopServer;
    end
    else
    begin
      UpdateStatus('WebSocket server failed to start: ' + TestWS.GetLastError, True);
    end;
  finally
    TestWS.Free;
  end;
end;

procedure TfrmSettings.btnResetClick(Sender: TObject);
begin
  if MessageDlg('Reset all settings to default values?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    ResetToDefaults;
  end;
end;

end.