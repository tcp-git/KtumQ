unit ConfigFormU;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, System.UITypes, acPNG;

type
  TConfigForm = class(TForm)
    pnlDatabase: TPanel;
    lblDatabaseTitle: TLabel;
    lblHost: TLabel;
    lblPort: TLabel;
    lblUsername: TLabel;
    lblPassword: TLabel;
    lblDatabaseName: TLabel;
    
    edtHost: TEdit;
    edtPort: TEdit;
    edtUsername: TEdit;
    edtPassword: TEdit;
    edtDatabaseName: TEdit;
    
    btnTestDB: TButton;
    
    pnlWebSocket: TPanel;
    lblWebSocketTitle: TLabel;
    lblWSURL: TLabel;
    lblWSPort: TLabel;
    
    edtWSURL: TEdit;
    edtWSPort: TEdit;
    
    btnTestWS: TButton;
    
    btnSave: TButton;
    btnCancel: TButton;
    chkStayOnTop: TCheckBox;
    img_autoconfig: TImage;
    
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnTestDBClick(Sender: TObject);
    procedure btnTestWSClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure img_autoconfigClick(Sender: TObject);

  private
    { Private declarations }
    procedure LoadConfiguration;
    procedure SaveConfiguration;
    procedure ShowMessageAtForm(const Msg: string);
    
  public
    { Public declarations }
  end;

var
  ConfigForm: TConfigForm;

implementation

{$R *.dfm}

uses
  IniFiles, Uni, UniProvider, MySQLUniProvider, sgcWebSocket, sgcWebSocket_Client;

procedure TConfigForm.FormCreate(Sender: TObject);
begin
  LoadConfiguration;
end;

procedure TConfigForm.FormShow(Sender: TObject);
begin
  // Read INI file and check StayOnTop when form is shown
  LoadConfiguration;
end;

procedure TConfigForm.LoadConfiguration;
var
  IniFile: TIniFile;
  ConfigPath: string;
begin
  ConfigPath := ExtractFilePath(Application.ExeName) + 'config.ini';
  
  if FileExists(ConfigPath) then
  begin
    IniFile := TIniFile.Create(ConfigPath);
    try
      // Load Database Configuration
      edtHost.Text          := IniFile.ReadString('Database', 'Host', 'localhost');
      edtPort.Text          := IntToStr(IniFile.ReadInteger('Database', 'Port', 3306));
      edtUsername.Text      := IniFile.ReadString('Database', 'Username', 'root');
      edtPassword.Text      := IniFile.ReadString('Database', 'Password', '');
      edtDatabaseName.Text  := IniFile.ReadString('Database', 'DatabaseName', 'queue_system');
      
      // Load WebSocket Configuration
      edtWSURL.Text         := IniFile.ReadString('WebSocket', 'ServerURL', 'localhost');
      edtWSPort.Text        := IntToStr(IniFile.ReadInteger('WebSocket', 'Port', 8080));
      
      // Load General Configuration
      chkStayOnTop.Checked := IniFile.ReadBool('General', 'StayOnTop', False);
      if chkStayOnTop.Checked then
        FormStyle := fsStayOnTop
      else
        FormStyle := fsNormal;
    finally
      IniFile.Free;
    end;
  end
  else
  begin
    // Set default values
    edtHost.Text := 'localhost';
    edtPort.Text := '3306';
    edtUsername.Text := 'root';
    edtPassword.Text := '';
    edtDatabaseName.Text := 'queue_system';
    edtWSURL.Text := 'localhost';
    edtWSPort.Text := '8080';
    chkStayOnTop.Checked := False;
  end;
end;

procedure TConfigForm.SaveConfiguration;
var
  IniFile: TIniFile;
  ConfigPath: string;
begin
  ConfigPath := ExtractFilePath(Application.ExeName) + 'config.ini';
  
  IniFile := TIniFile.Create(ConfigPath);
  try
    // Save Database Configuration
    IniFile.WriteString('Database', 'Host', edtHost.Text);
    IniFile.WriteInteger('Database', 'Port', StrToIntDef(edtPort.Text, 3306));
    IniFile.WriteString('Database', 'Username', edtUsername.Text);
    IniFile.WriteString('Database', 'Password', edtPassword.Text);
    IniFile.WriteString('Database', 'DatabaseName', edtDatabaseName.Text);
    
    // Save WebSocket Configuration
    IniFile.WriteString('WebSocket', 'ServerURL', edtWSURL.Text);
    IniFile.WriteInteger('WebSocket', 'Port', StrToIntDef(edtWSPort.Text, 8080));
    
    // Save General Configuration
    IniFile.WriteBool('General', 'StayOnTop', chkStayOnTop.Checked);
  finally
    IniFile.Free;
  end;


end;

procedure TConfigForm.ShowMessageAtForm(const Msg: string);
var
  MsgForm: TForm;
begin
  MsgForm := CreateMessageDialog(Msg, mtInformation, [mbOK]);
  try
    MsgForm.PopupParent := Self;
    MsgForm.PopupMode := pmAuto;
    if Self.Visible then
    begin
      MsgForm.Position := poDesigned;
      MsgForm.Left := Self.Left + (Self.Width - MsgForm.Width) div 2;
      MsgForm.Top := Self.Top + (Self.Height - MsgForm.Height) div 2;
    end
    else
    begin
      MsgForm.Position := poScreenCenter;
    end;
    MsgForm.ShowModal;
  finally
    MsgForm.Free;
  end;
end;

procedure TConfigForm.btnTestDBClick(Sender: TObject);
var
  TestConnection: TUniConnection;
  TestProvider: TMySQLUniProvider;
begin
  TestConnection := TUniConnection.Create(nil);
  TestProvider := TMySQLUniProvider.Create(nil);
  try
    TestConnection.ProviderName := 'MySQL';
    TestConnection.Server := edtHost.Text;
    TestConnection.Port := StrToIntDef(edtPort.Text, 3306);
    TestConnection.Username := edtUsername.Text;
    TestConnection.Password := edtPassword.Text;
    TestConnection.Database := edtDatabaseName.Text;
    
    try
      TestConnection.Connect;
      ShowMessageAtForm('Database connection successful!');
      TestConnection.Close;
    except
      on E: Exception do
        ShowMessageAtForm('Database connection failed: ' + E.Message);
    end;
  finally
    TestConnection.Free;
    TestProvider.Free;
  end;
end;

procedure TConfigForm.btnTestWSClick(Sender: TObject);
var
  TestClient: TsgcWebSocketClient;
begin
  TestClient := TsgcWebSocketClient.Create(nil);
  try
    TestClient.Host := edtWSURL.Text;
    TestClient.Port := StrToIntDef(edtWSPort.Text, 8080);
    
    try
      TestClient.Active := True;
      Sleep(1000); // Wait for connection
      
      if TestClient.Active then
      begin
        ShowMessageAtForm('WebSocket connection successful!');
        TestClient.Active := False;
      end
      else
        ShowMessageAtForm('WebSocket connection failed!');
    except
      on E: Exception do
        ShowMessageAtForm('WebSocket connection failed: ' + E.Message);
    end;
  finally
    TestClient.Free;
  end;
end;

procedure TConfigForm.btnSaveClick(Sender: TObject);
begin
  SaveConfiguration;
//  ShowMessage('Configuration saved successfully!');
  ModalResult := mrOk;
end;

procedure TConfigForm.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TConfigForm.img_autoconfigClick(Sender: TObject);
begin
  edtHost.Text          := '172.16.111.240';
  edtPort.Text          := '3306';
  edtUsername.Text      := 'supervisor';
  edtPassword.Text      := 'xsuper';
  edtDatabaseName.Text  := 'queue_system';
  edtWSURL.Text         := '172.16.111.240';
  edtWSPort.Text        := '4444';

end;

end.
