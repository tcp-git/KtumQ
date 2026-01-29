unit MainFormU;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, Uni, UniProvider, MySQLUniProvider, sgcWebSocket, sgcWebSocket_Classes,    System.DateUtils,
  sgcWebSocket_Client, sgcBase_Classes, sgcSocket_Classes, sgcTCP_Classes, sgcWebSocket_Classes_Indy, Data.DB, MemDS,
  DBAccess, JvAppInst, System.UITypes;

type
  TMainForm = class(TForm)
    lblServiceCounter: TLabel;
    lblSelectedCounter: TLabel;
    lblBarcodeInput: TLabel;
    lblPriorityBarcodeInput: TLabel;
    lblManualCall: TLabel;
    StatusBar1: TStatusBar;
    btnConfig: TButton;
    btnResetDaily: TButton;
    cmbServiceCounter: TComboBox;
    edtBarcodeInput: TEdit;
    edtPriorityBarcodeInput: TEdit;
    btnCallRoom1: TButton;
    btnCallRoom2: TButton;
    btnCallRoom3: TButton;
    btnCallRoom4: TButton;
    btnTestSend: TButton;
    UniConnection1: TUniConnection;
    UniQuery1: TUniQuery;
    MySQLUniProvider1: TMySQLUniProvider;
    sgcWebSocketClient1: TsgcWebSocketClient;
    RefreshTimer: TTimer;
    JvAppInstances1: TJvAppInstances;
    memoDebug: TMemo;
    btnBarcodeInput: TButton;
    btnPriorityBarcodeInput: TButton;
    Button1: TButton;
    
    procedure btnBarcodeInputClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure RefreshTimerTimer(Sender: TObject);
    procedure sgcWebSocketClient1Connect(Connection: TsgcWSConnection);
    procedure sgcWebSocketClient1Disconnect(Connection: TsgcWSConnection; Code: Integer);
    procedure sgcWebSocketClient1Error(Connection: TsgcWSConnection; const Error: string);
    procedure btnConfigClick(Sender: TObject);
    procedure cmbServiceCounterChange(Sender: TObject);
    procedure edtBarcodeInputKeyPress(Sender: TObject; var Key: Char);
    procedure edtPriorityBarcodeInputKeyPress(Sender: TObject; var Key: Char);
    procedure btnCallRoom1Click(Sender: TObject);
    procedure btnCallRoom2Click(Sender: TObject);
    procedure btnCallRoom3Click(Sender: TObject);
    procedure btnCallRoom4Click(Sender: TObject);
    procedure btnConfigDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure btnResetDailyClick(Sender: TObject);
    procedure btnTestSendClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure btnHideDebugClick(Sender: TObject);
    procedure btnPriorityBarcodeInputClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);

  private
    FDatabaseConnected: Boolean;
    FWebSocketConnected: Boolean;
    FSelectedCounter: Integer;
    FOfflineMessageQueue: TStringList;
    FReconnectTimer: TTimer;
    FReconnectAttempt: Integer;
    FReconnectDelay: Integer;
    FLongWaitCheckCounter: Integer;
    FbtnHideDebug: TButton;
    FCollapsedHeight: Integer;
    FExpandedHeight: Integer;
    FDebugMemoOriginalTop: Integer;
    FButton1Timer, FButton2Timer, FButton3Timer, FButton4Timer: TTimer;
    function InputPassword(const ACaption, APrompt: string; var AValue: string): Boolean;
    procedure ShowMessageAtForm(const Msg: string);
    function MessageDlgAtForm(const Msg: string; DlgType: TMsgDlgType; Buttons: TMsgDlgButtons): Integer;
    procedure LoadConfiguration;
    procedure ConnectDatabase;
    procedure ConnectWebSocket;
    procedure UpdateConnectionStatus;
    procedure InitializeServiceCounter;
    procedure UpdateButtonStates;
    procedure OnReconnectTimer(Sender: TObject);
    procedure UpdateSelectedCounterDisplay;
    procedure ProcessBarcodeInput(const Barcode: string);
    function FindQueueByBarcode(const Barcode: string): Boolean;
    procedure UpdateQueueStatus(const Barcode: string);
    procedure SendQueueCalledMessage(const QueueNumber, RoomName: string);
    procedure SendOfflineMessages;
    procedure ProcessPriorityBarcodeInput(const Barcode: string);
    procedure SendPriorityQueueUpdateMessage;
    procedure CallNextQueueManually(RoomID: Integer);
    function GetNextQueueForRoom(RoomID: Integer; out QueueNumber: string; out QueueBarcode: string): Boolean;
    procedure RefreshQueueStatus;
    function GetWaitingQueueCount(RoomID: Integer): Integer;
    function GetNextQueueNumber(RoomID: Integer): string;
    procedure UpdateQueueStatusDisplay;
    function GetTotalQueues(ARoom: Integer): Integer;
    function GetWaitingQueues(ARoom: Integer): Integer;
    function GetServedQueues(ARoom: Integer): Integer;
    procedure AddDebugLog(const AMessage: string);
    function GetLongWaitingQueues: string;
    procedure DisableButtonTemporarily(Button: TButton);
    procedure OnButtonEnableTimer(Sender: TObject);
    procedure OnAutoCloseTimer(Sender: TObject);
  public
    property SelectedCounter: Integer read FSelectedCounter;
    property OfflineMessageQueue: TStringList read FOfflineMessageQueue;
    procedure MarkQueueAsPriority(const Barcode: string);
  end;

var
  MainForm: TMainForm;

implementation

//fstatus = '2' : "สถานะรอเรียก" (Waiting)
//ถูกกำหนดตอน สร้างคิวใหม่ (ใน Dispenser: InsertQueueToDatabase)
//ใช้สำหรับดึงรายการคิวที่รอยู่เพื่อมาแสดงจำนวนรอ
//fstatus = '1' : "สถานะถูกเรียกแล้ว/รับบริการแล้ว" (Served/Called)
//ถูกอัปเดตเมื่อ กดเรียกคิว (ใน Caller: UpdateQueueStatus)
//เพื่อบอกว่าคิวนี้สิ้นสุดการรอแล้ว

{$R *.dfm}

uses
  System.IniFiles, ConfigFormU;

procedure TMainForm.FormCreate(Sender: TObject);
var
  InstanceID: string;
begin
  FDatabaseConnected := False;
  
  // สร้าง unique ID สำหรับ instance นี้
  InstanceID := FormatDateTime('hhnnss', Now) + IntToStr(Random(9999));
  AddDebugLog('=== Caller Instance Started: ' + InstanceID + ' ===');
  FWebSocketConnected := False;
  FSelectedCounter    := 0;
  FReconnectAttempt   := 0;
  FReconnectDelay     := 2;  // Initial delay 2 seconds
  
  FOfflineMessageQueue  := TStringList.Create;
  
  RefreshTimer.Interval := 2000;
  RefreshTimer.Enabled  := False;
  
  // Create single timer for reconnection (1 second interval for smooth countdown)
  FReconnectTimer := TTimer.Create(Self);
  FReconnectTimer.Interval := 1000;
  FReconnectTimer.Enabled  := False;
  FReconnectTimer.OnTimer  := OnReconnectTimer;
  
  // Initialize button timers
  FButton1Timer := nil;
  FButton2Timer := nil;
  FButton3Timer := nil;
  FButton4Timer := nil;
  
  InitializeServiceCounter;
  
  LoadConfiguration;
  ConnectDatabase;
  
  ConnectWebSocket;
  
  if FDatabaseConnected then
  begin
    RefreshTimer.Enabled := True;
    RefreshQueueStatus;
  end;
  
  UpdateConnectionStatus;
  UpdateButtonStates;

  // กำหนดความสูงฟอร์มแบบคงที่ (ยืด/หด)
  FExpandedHeight := 562;
  FCollapsedHeight := 430;
  FDebugMemoOriginalTop := memoDebug.Top; // เก็บตำแหน่งพื้นฐาน
  
  // ตั้งค่าเริ่มต้นสำหรับ memoDebug
  memoDebug.Visible := False;
  memoDebug.Top     := 1000; // เลื่อนออกนอกขอบฟอร์ม
  Self.KeyPreview   := True;
  Self.OnKeyDown    := FormKeyDown;
  Self.OnShow       := FormShow;

  // สร้างปุ่มซ่อน Log แบบไดนามิก
  FbtnHideDebug := TButton.Create(Self);
  if Assigned(memoDebug.Parent) then
    FbtnHideDebug.Parent := memoDebug.Parent
  else
    FbtnHideDebug.Parent := Self;

  FbtnHideDebug.Caption := 'ซ่อน Log';
  FbtnHideDebug.Width   := 80;
  FbtnHideDebug.Height  := 25;
  FbtnHideDebug.Visible := False;
  FbtnHideDebug.OnClick := btnHideDebugClick;
  
  // วางตำแหน่งที่มุมขวาบนของ memoDebug (ตำแหน่งสัมพันธ์)
  FbtnHideDebug.Left := memoDebug.Left + memoDebug.Width - FbtnHideDebug.Width;
  FbtnHideDebug.Top := memoDebug.Top + 2;
  FbtnHideDebug.Anchors := [akRight, akTop];

  // เริ่มต้นด้วยการซ่อน Log และหดฟอร์ม
  Self.Height := FCollapsedHeight;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
var
  IniFile: TIniFile;
  ConfigPath: string;
begin
  RefreshTimer.Enabled := False;
  
  ConfigPath := ExtractFilePath(Application.ExeName) + 'config.ini';
  IniFile := TIniFile.Create(ConfigPath);
  try
    IniFile.WriteInteger('Caller', 'WindowLeft', Left);
    IniFile.WriteInteger('Caller', 'WindowTop', Top);
  finally
    IniFile.Free;
  end;
  
  // Stop reconnect timer
  if Assigned(FReconnectTimer) then
    FReconnectTimer.Enabled := False;
  
  if UniConnection1.Connected then
    UniConnection1.Close;
  
  // Cleanup button timers
  if Assigned(FButton1Timer) then
  begin
    FButton1Timer.Free;
    FButton1Timer := nil;
  end;
  if Assigned(FButton2Timer) then
  begin
    FButton2Timer.Free;
    FButton2Timer := nil;
  end;
  if Assigned(FButton3Timer) then
  begin
    FButton3Timer.Free;
    FButton3Timer := nil;
  end;
  if Assigned(FButton4Timer) then
  begin
    FButton4Timer.Free;
    FButton4Timer := nil;
  end;
  
  if Assigned(FOfflineMessageQueue) then
    FOfflineMessageQueue.Free;
end;

procedure TMainForm.LoadConfiguration;
var
  IniFile: TIniFile;
  ConfigPath: string;
  SavedCounter: Integer;
  SavedLeft, SavedTop: Integer;
begin
  ConfigPath := ExtractFilePath(Application.ExeName) + 'config.ini';
  
  if not FileExists(ConfigPath) then
  begin
    ShowMessageAtForm('ไม่พบไฟล์ config.ini กรุณาตั้งค่าระบบ');
    Exit;
  end;
  
  IniFile := TIniFile.Create(ConfigPath);
  try
    // Database configuration
    UniConnection1.Server := IniFile.ReadString('Database', 'Host', 'localhost');
    UniConnection1.Port := IniFile.ReadInteger('Database', 'Port', 3306);
    UniConnection1.Username := IniFile.ReadString('Database', 'Username', 'root');
    UniConnection1.Password := IniFile.ReadString('Database', 'Password', '');
    UniConnection1.Database := IniFile.ReadString('Database', 'DatabaseName', 'queue_system');
    
    // WebSocket configuration
    sgcWebSocketClient1.Host := IniFile.ReadString('WebSocket', 'ServerURL', 'localhost');
    sgcWebSocketClient1.Port := IniFile.ReadInteger('WebSocket', 'Port', 8080);
    
    // Load saved service counter
    SavedCounter := IniFile.ReadInteger('Caller', 'ServiceCounter', 0);
    if (SavedCounter >= 1) and (SavedCounter <= 9) then
    begin
      cmbServiceCounter.ItemIndex := SavedCounter;
      FSelectedCounter := SavedCounter;
      UpdateSelectedCounterDisplay;
    end;
    
    // Load window position
    SavedLeft := IniFile.ReadInteger('Caller', 'WindowLeft', -1);
    SavedTop  := IniFile.ReadInteger('Caller', 'WindowTop', -1);
    if (SavedLeft >= 0) and (SavedTop >= 0) then
    begin
      Left := SavedLeft;
      Top := SavedTop;
      Position := poDesigned;
    end;
    
    // Load StayOnTop configuration
    if IniFile.ReadBool('General', 'StayOnTop', False) then
      FormStyle := fsStayOnTop
    else
      FormStyle := fsNormal;
  finally
    IniFile.Free;
  end;
end;

procedure TMainForm.ConnectDatabase;
begin
  try
    UniConnection1.Connected := True;
    FDatabaseConnected := True;
  except
    on E: Exception do
    begin
      FDatabaseConnected := False;
      ShowMessageAtForm('ไม่สามารถเชื่อมต่อฐานข้อมูลได้: ' + E.Message);
    end;
  end;
end;

procedure TMainForm.ShowMessageAtForm(const Msg: string);
begin
  MessageDlgAtForm(Msg, mtInformation, [mbOK]);
end;

function TMainForm.MessageDlgAtForm(const Msg: string; DlgType: TMsgDlgType; Buttons: TMsgDlgButtons): Integer;
var
  MsgForm: TForm;
  AutoCloseTimer: TTimer;
begin
  // สร้าง message dialog
  MsgForm := CreateMessageDialog(Msg, DlgType, Buttons);
  try
    MsgForm.PopupParent := Self;
    MsgForm.PopupMode   := pmAuto;
    
    // สร้าง Timer สำหรับ auto-close (10 วินาที)
    AutoCloseTimer := TTimer.Create(MsgForm);
    AutoCloseTimer.Interval := 5000; // 10 วินาที
    AutoCloseTimer.Tag := NativeInt(MsgForm); // เก็บ reference ของ MsgForm
    AutoCloseTimer.OnTimer := OnAutoCloseTimer;
    AutoCloseTimer.Enabled := True;
    
    // ตรวจสอบว่าฟอร์มปัจจุบันแสดงผลอยู่หรือไม่
    if Self.Visible then
    begin
      // ถ้าฟอร์มแสดงผลอยู่ ให้แสดงที่ตำแหน่งของฟอร์ม
      MsgForm.Position  := poDesigned;
      MsgForm.Left      := Self.Left + (Self.Width  - MsgForm.Width) div 2;
      MsgForm.Top       := Self.Top  + (Self.Height - MsgForm.Height) div 2;
    end
    else
    begin
      // ถ้าฟอร์มยังไม่แสดงผล (เช่น ช่วง FormCreate) ให้แสดงกลางหน้าจอปกติ
      MsgForm.Position := poScreenCenter;
    end;
    
    Result := MsgForm.ShowModal;
    
    // หยุด Timer เมื่อผู้ใช้กดปุ่มก่อนเวลา
    AutoCloseTimer.Enabled := False;
  finally
    MsgForm.Free;
  end;
end;

procedure TMainForm.ConnectWebSocket;
begin
  try
    if not sgcWebSocketClient1.Active then
      sgcWebSocketClient1.Active := True;
  except
    on E: Exception do
      AddDebugLog('Connect error: ' + E.Message);
  end;
end;

procedure TMainForm.OnAutoCloseTimer(Sender: TObject);
var
  Form: TForm;
begin
  // ใช้ Tag เก็บ reference ของ MsgForm
  Form := TForm(TTimer(Sender).Tag);
  if Assigned(Form) and Form.Visible then
  begin
    Form.ModalResult := mrOk;
    TTimer(Sender).Enabled := False;
  end;
end;

procedure TMainForm.RefreshTimerTimer(Sender: TObject);
begin
  UpdateConnectionStatus;
  
  // รีเฟรชข้อมูลสถานะคิวทุก 2 วินาที
  if FDatabaseConnected then
    RefreshQueueStatus;
end;

procedure TMainForm.sgcWebSocketClient1Connect(Connection: TsgcWSConnection);
begin
  FWebSocketConnected := True;
  AddDebugLog('WebSocket Connected');
  
  // Stop reconnect timer and reset counters
  FReconnectTimer.Enabled := False;
  FReconnectAttempt := 0;
  FReconnectDelay := 2;
  
  UpdateConnectionStatus;
  UpdateButtonStates;
  SendOfflineMessages;
end;

procedure TMainForm.sgcWebSocketClient1Disconnect(Connection: TsgcWSConnection; Code: Integer);
begin
  FWebSocketConnected := False;
  AddDebugLog(Format('WebSocket Disconnected (Code: %d)', [Code]));
  
  // Start reconnect timer
  if FReconnectAttempt = 0 then
  begin
    FReconnectAttempt := 1;
    FReconnectDelay := 2;  // Initial delay
  end;
  FReconnectTimer.Enabled := True;
  
  UpdateConnectionStatus;
  UpdateButtonStates;
end;

procedure TMainForm.sgcWebSocketClient1Error(Connection: TsgcWSConnection; const Error: string);
begin
  FWebSocketConnected := False;
  AddDebugLog('WebSocket Error: ' + Error);
  
  if not FWebSocketConnected then
  begin
    // Start reconnect if not already running
    if not FReconnectTimer.Enabled then
    begin
      FReconnectAttempt := 1;
      FReconnectDelay := 2;
      FReconnectTimer.Enabled := True;
    end;
  end;
  
  UpdateConnectionStatus;
  UpdateButtonStates;
end;

procedure TMainForm.UpdateConnectionStatus;
begin
  if Assigned(StatusBar1) then
  begin
    if FDatabaseConnected then
      StatusBar1.Panels[0].Text := 'DB: OK'
    else
      StatusBar1.Panels[0].Text := 'DB: Error';
      
    if FWebSocketConnected then
      StatusBar1.Panels[1].Text := 'CLK: OK'
    else if FReconnectTimer.Enabled then
      StatusBar1.Panels[1].Text := Format('CLK: Reconnect #%d (%ds)', [FReconnectAttempt, FReconnectDelay])
    else
      StatusBar1.Panels[1].Text := 'CLK:Disconn';
  end;
end;

procedure TMainForm.UpdateButtonStates;
begin
  // Enable buttons if database is connected (WebSocket is optional for calling queue)
  btnCallRoom1.Enabled := FDatabaseConnected;
  btnCallRoom2.Enabled := FDatabaseConnected;
  btnCallRoom3.Enabled := FDatabaseConnected;
  btnCallRoom4.Enabled := FDatabaseConnected;
end;

procedure TMainForm.OnReconnectTimer(Sender: TObject);
const
  RECONNECT_INITIAL_DELAY = 2;
  RECONNECT_MAX_DELAY = 30;
var
  NextDelay: Integer;
begin
  // Check if already reconnected
  if FWebSocketConnected then
  begin
    FReconnectTimer.Enabled := False;
    FReconnectAttempt := 0;
    FReconnectDelay := RECONNECT_INITIAL_DELAY;
    UpdateConnectionStatus;
    Exit;
  end;
  
  Dec(FReconnectDelay);
  UpdateConnectionStatus;
  
  if FReconnectDelay <= 0 then
  begin
    // Attempt reconnection
    AddDebugLog(Format('Reconnect attempt #%d', [FReconnectAttempt]));
    
    try
      if not sgcWebSocketClient1.Active then
        sgcWebSocketClient1.Active := True;
    except
      on E: Exception do
        AddDebugLog('Reconnect failed: ' + E.Message);
    end;
    
    // Calculate next delay with exponential backoff
    // 2^(attempt-1) * RECONNECT_INITIAL_DELAY, capped at RECONNECT_MAX_DELAY
    Inc(FReconnectAttempt);
    if FReconnectAttempt = 1 then
      NextDelay := RECONNECT_INITIAL_DELAY
    else
      NextDelay := RECONNECT_INITIAL_DELAY * (1 shl (FReconnectAttempt - 2));
    
    if NextDelay > RECONNECT_MAX_DELAY then
      NextDelay := RECONNECT_MAX_DELAY;
      
    FReconnectDelay := NextDelay;
    AddDebugLog(Format('Next reconnect in %d seconds', [FReconnectDelay]));
  end;
end;

procedure TMainForm.btnConfigClick(Sender: TObject);
var
  ConfigForm: TConfigForm;
begin
  ConfigForm := TConfigForm.Create(Self);
  try
    ConfigForm.PopupParent := Self;
    ConfigForm.PopupMode := pmAuto;
    if ConfigForm.ShowModal = mrOk then
    begin
      // Reload configuration and reconnect
      if UniConnection1.Connected then
        UniConnection1.Close;
      
      // Stop reconnect timer and disconnect
      FReconnectTimer.Enabled := False;
      if sgcWebSocketClient1.Active then
        sgcWebSocketClient1.Active := False;
        
      LoadConfiguration;
      ConnectDatabase;
      ConnectWebSocket;

      if FDatabaseConnected then
        RefreshTimer.Enabled := True
      else
        RefreshTimer.Enabled := False;
        
      UpdateConnectionStatus;
    end;
  finally
    ConfigForm.Free;
  end;
end;

procedure TMainForm.InitializeServiceCounter;
var
  I: Integer;
begin
  // Populate ComboBox with counter numbers 1-9
  cmbServiceCounter.Clear;
  cmbServiceCounter.Items.Add('-- เลือกช่องบริการ --');
  for I := 1 to 6 do
    cmbServiceCounter.Items.Add(IntToStr(I));
  
  // Set default selection to prompt
  cmbServiceCounter.ItemIndex := 0;
  
  // Update display
  UpdateSelectedCounterDisplay;
end;

procedure TMainForm.cmbServiceCounterChange(Sender: TObject);
var
  IniFile: TIniFile;
  ConfigPath: string;
begin
  // Store selected counter (0 if no valid selection)
  if cmbServiceCounter.ItemIndex > 0 then
    FSelectedCounter := cmbServiceCounter.ItemIndex
  else
    FSelectedCounter := 0;
  
  // Update display
  UpdateSelectedCounterDisplay;
  
  // Save to INI file
  ConfigPath := ExtractFilePath(Application.ExeName) + 'config.ini';
  IniFile := TIniFile.Create(ConfigPath);
  try
    IniFile.WriteInteger('Caller', 'ServiceCounter', FSelectedCounter);
  finally
    IniFile.Free;
  end;
end;

procedure TMainForm.UpdateSelectedCounterDisplay;
begin
  if FSelectedCounter > 0 then
    lblSelectedCounter.Caption := 'ช่องบริการที่เลือก: ' + IntToStr(FSelectedCounter)
  else
    lblSelectedCounter.Caption := 'ช่องบริการที่เลือก: ยังไม่ได้เลือก';
end;

procedure TMainForm.edtBarcodeInputKeyPress(Sender: TObject; var Key: Char);
var
  Barcode: string;
begin
  // เมื่อกด Enter ให้ประมวลผลบาร์โค้ด
  if Key = #13 then
  begin
    Key := #0; // ป้องกันเสียง beep
    Barcode := Trim(edtBarcodeInput.Text);
    
    if Barcode <> '' then
    begin
      ProcessBarcodeInput(Barcode);
      edtBarcodeInput.Clear; // ล้างช่องกรอกหลังประมวลผล
    end;
  end;
end;

procedure TMainForm.ProcessBarcodeInput(const Barcode: string);
begin
  // ตรวจสอบว่าเชื่อมต่อฐานข้อมูลหรือไม่
  if not FDatabaseConnected then
  begin
    ShowMessageAtForm('ไม่สามารถเรียกคิวได้: ไม่ได้เชื่อมต่อฐานข้อมูล');
    Exit;
  end;
  
  // ตรวจสอบว่าเลือกช่องบริการแล้วหรือไม่
  if FSelectedCounter = 0 then
  begin
    ShowMessageAtForm('กรุณาเลือกช่องบริการก่อนเรียกคิว');
    Exit;
  end;
  
  // ค้นหาคิวจากบาร์โค้ด
  if not FindQueueByBarcode(Barcode) then
  begin
    ShowMessageAtForm('ไม่พบหมายเลขคิวในระบบ');
    Exit;
  end;
  
  // อัพเดทสถานะคิว
  try
    UpdateQueueStatus(Barcode);
    ShowMessageAtForm('เรียกคิวสำเร็จ');
  except
    on E: Exception do
      ShowMessageAtForm('เกิดข้อผิดพลาดในการเรียกคิว: ' + E.Message);
  end;
end;

// ค้นหาคิวจากบาร์โค้ด (เฉพาะวันปัจจุบัน)
function TMainForm.FindQueueByBarcode(const Barcode: string): Boolean;
var
  QueueDate: TDate;
  CurrentDate: TDate;
begin
  Result := False;
  
  try
    UniQuery1.Close;
    UniQuery1.SQL.Text := 
      'SELECT id, qdisplay, room, fstatus, timestamp ' +
      'FROM queue_data ' +
      'WHERE barcodes = :barcode';
    UniQuery1.ParamByName('barcode').AsString := Barcode;
    UniQuery1.Open;
    
    if UniQuery1.IsEmpty then
    begin
      ShowMessageAtForm('ไม่พบคิวนี้ในระบบ');
      Result := False;
      Exit;
    end;
    
    // ตรวจสอบว่าคิวเป็นของวันปัจจุบันหรือไม่
    QueueDate := DateOf(UniQuery1.FieldByName('timestamp').AsDateTime);
    CurrentDate := DateOf(Now);
    
    if QueueDate <> CurrentDate then
    begin
      ShowMessageAtForm('คิวนี้เป็นของวันก่อนหน้า ไม่สามารถเรียกได้');
      Result := False;
      Exit;
    end;
    
    // ตรวจสอบว่าคิวถูกเรียกไปแล้วหรือไม่
//    if UniQuery1.FieldByName('fstatus').AsString = '1' then
//    begin
//      ShowMessageAtForm('คิวนี้ถูกเรียกไปแล้ว');
//      Result := False;
//      Exit;
//    end;
    
    Result := True;
  except
    on E: Exception do
    begin
      ShowMessageAtForm('เกิดข้อผิดพลาดในการค้นหาคิว: ' + E.Message);
      Result := False;
    end;
  end;
end;

procedure TMainForm.UpdateQueueStatus(const Barcode: string);
var
  QueueNumber, RoomName: string;
  RoomID: Integer;
  UpdateQuery: TUniQuery;
  TimeConfirmExists: Boolean;
begin
  // ดึงข้อมูลคิวก่อนอัพเดท
  UniQuery1.Close;
  UniQuery1.SQL.Text := 
    'SELECT qdisplay, room, time_confirm ' +
    'FROM queue_data ' +
    'WHERE barcodes = :barcode';
  UniQuery1.ParamByName('barcode').AsString := Barcode;
  UniQuery1.Open;
  
  if UniQuery1.IsEmpty then
    raise Exception.Create('ไม่พบข้อมูลคิว');
  
  QueueNumber := UniQuery1.FieldByName('qdisplay').AsString;
  RoomID := UniQuery1.FieldByName('room').AsInteger;
  
  // ตรวจสอบว่า time_confirm มีค่าอยู่แล้วหรือไม่
  TimeConfirmExists := not UniQuery1.FieldByName('time_confirm').IsNull;
  
  // แปลง room ID เป็นชื่อประเภทบริการ
  case RoomID of
    1: RoomName := 'ยาปริมาณมาก';
    2: RoomName := 'ยาปริมาณน้อย';
    3: RoomName := 'กลับบ้านไม่มียา';
    4: RoomName := 'ยาขอก่อน';
  else
    RoomName := 'ไม่ทราบ';
  end;
  
  // อัพเดทสถานะคิวในฐานข้อมูล
  UpdateQuery := TUniQuery.Create(nil);
  try
    UpdateQuery.Connection := UniConnection1;
    
    // ถ้า time_confirm มีค่าอยู่แล้ว ให้ update last_confirm_time แทน
    // ถ้ายังไม่มีค่า ให้ update time_confirm เหมือนเดิม
    if TimeConfirmExists then
    begin
      UpdateQuery.SQL.Text := 
        'UPDATE queue_data ' +
        'SET fstatus = ''1'', ' +
        '    counters = :counter, ' +
        '    last_confirm_time = NOW() ' +
        'WHERE barcodes = :barcode';
    end
    else
    begin
      UpdateQuery.SQL.Text := 
        'UPDATE queue_data ' +
        'SET fstatus = ''1'', ' +
        '    counters = :counter, ' +
        '    time_confirm = NOW() ' +
        'WHERE barcodes = :barcode';
    end;
    
    UpdateQuery.ParamByName('counter').AsString := IntToStr(FSelectedCounter);
    UpdateQuery.ParamByName('barcode').AsString := Barcode;
    UpdateQuery.Execute;
    
    // ส่งข้อความ WebSocket
    SendQueueCalledMessage(QueueNumber, RoomName);
  finally
    UpdateQuery.Free;
  end;
end;

function TMainForm.GetTotalQueues(ARoom: Integer): Integer;
var
  Query: TUniQuery;
begin
  Result := 0;
  if not UniConnection1.Connected then Exit;
  
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := UniConnection1;
    Query.SQL.Text := 'SELECT COUNT(*) as total FROM queue_data WHERE room = :room AND timestamp >= CURDATE() AND timestamp < CURDATE() + INTERVAL 1 DAY';
    Query.ParamByName('room').AsInteger := ARoom;
    Query.Open;
    if not Query.IsEmpty then
      Result := Query.FieldByName('total').AsInteger;
  finally
    Query.Free;
  end;
end;

function TMainForm.GetWaitingQueues(ARoom: Integer): Integer;
var
  Query: TUniQuery;
begin
  Result := 0;
  if not UniConnection1.Connected then Exit;
  
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := UniConnection1;
    Query.SQL.Text := 'SELECT COUNT(*) as waiting FROM queue_data WHERE room = :room AND fstatus = ''2'' AND timestamp >= CURDATE() AND timestamp < CURDATE() + INTERVAL 1 DAY';
    Query.ParamByName('room').AsInteger := ARoom;
    Query.Open;
    if not Query.IsEmpty then
      Result := Query.FieldByName('waiting').AsInteger;
  finally
    Query.Free;
  end;
end;

function TMainForm.GetServedQueues(ARoom: Integer): Integer;
var
  Query: TUniQuery;
begin
  Result := 0;
  if not UniConnection1.Connected then Exit;
  
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := UniConnection1;
    Query.SQL.Text := 'SELECT COUNT(*) as served FROM queue_data WHERE room = :room AND fstatus != ''2'' AND timestamp >= CURDATE() AND timestamp < CURDATE() + INTERVAL 1 DAY';
    Query.ParamByName('room').AsInteger := ARoom;
    Query.Open;
    if not Query.IsEmpty then
      Result := Query.FieldByName('served').AsInteger;
  finally
    Query.Free;
  end;
end;

procedure TMainForm.AddDebugLog(const AMessage: string);
var
  Timestamp: string;
begin
  if not Assigned(memoDebug) then Exit;
  
  Timestamp := FormatDateTime('dd-mm-yy hh:nn:ss', Now);
  memoDebug.Lines.Add(Timestamp + ' : ' + AMessage);
  
  // Keep only last 100 lines
  while memoDebug.Lines.Count > 100 do
    memoDebug.Lines.Delete(0);
    
  // Scroll to bottom
  SendMessage(memoDebug.Handle, EM_LINESCROLL, 0, memoDebug.Lines.Count);
end;

procedure TMainForm.btnBarcodeInputClick(Sender: TObject);
var  Barcode: string;
begin
    Barcode := Trim(edtBarcodeInput.Text);

    if Barcode <> '' then
    begin
      ProcessBarcodeInput(Barcode);
      edtBarcodeInput.Clear; // ล้างช่องกรอกหลังประมวลผล
    end;

end;

function TMainForm.GetLongWaitingQueues: string;
var
  Query: TUniQuery;
  LongWaitList: TStringList;
begin
  Result := '[]';
  
  if not UniConnection1.Connected then Exit;
  
  Query := TUniQuery.Create(nil);
  LongWaitList := TStringList.Create;
  try
    Query.Connection := UniConnection1;
    // หาคิวที่ถูกทำเครื่องหมายเป็นคิวรอนาน (period = '1')
    // เรียงจากใหม่ไปเก่า (DESC) เพื่อให้รายการใหม่อยู่บน
    Query.SQL.Text := 
      'SELECT qdisplay, room ' +
      'FROM queue_data ' +
      'WHERE fstatus = ''2'' AND period = ''1'' AND timestamp >= CURDATE() AND timestamp < CURDATE() + INTERVAL 1 DAY ' +
      'ORDER BY timestamp DESC ' +
      'LIMIT 6';
    Query.Open;
    
    while not Query.Eof do
    begin
      LongWaitList.Add(Format('{"queue":"%s","room":%d}',
        [Query.FieldByName('qdisplay').AsString,
         Query.FieldByName('room').AsInteger]));
      Query.Next;
    end;
    
    if LongWaitList.Count > 0 then
      Result := '[' + String.Join(',', LongWaitList.ToStringArray) + ']';
      
  finally
    Query.Free;
    LongWaitList.Free;
  end;
end;

procedure TMainForm.DisableButtonTemporarily(Button: TButton);
var
  ButtonTimer: TTimer;
begin
  // ปิดการใช้งานปุ่มทันที
  Button.Enabled := False;
  
  // กำหนด Timer ตามปุ่มที่เลือก
  if Button = btnCallRoom1 then
  begin
    if Assigned(FButton1Timer) then
    begin
      FButton1Timer.Free;
      FButton1Timer := nil;
    end;
    FButton1Timer := TTimer.Create(Self);
    ButtonTimer   := FButton1Timer;
  end
  else if Button = btnCallRoom2 then
  begin
    if Assigned(FButton2Timer) then
    begin
      FButton2Timer.Free;
      FButton2Timer := nil;
    end;
    FButton2Timer := TTimer.Create(Self);
    ButtonTimer   := FButton2Timer;
  end
  else if Button = btnCallRoom3 then
  begin
    if Assigned(FButton3Timer) then
    begin
      FButton3Timer.Free;
      FButton3Timer := nil;
    end;
    FButton3Timer := TTimer.Create(Self);
    ButtonTimer   := FButton3Timer;
  end
  else if Button = btnCallRoom4 then
  begin
    if Assigned(FButton4Timer) then
    begin
      FButton4Timer.Free;
      FButton4Timer := nil;
    end;
    FButton4Timer := TTimer.Create(Self);
    ButtonTimer   := FButton4Timer;
  end
  else
    Exit; // ไม่ใช่ปุ่มที่รองรับ
  
  // ตั้งค่า Timer
  ButtonTimer.Interval  := 5000; // 5 วินาที
  ButtonTimer.Tag       := Integer(Button); // เก็บ reference ของปุ่ม
  ButtonTimer.OnTimer   := OnButtonEnableTimer;
  ButtonTimer.Enabled   := True;
end;

procedure TMainForm.OnButtonEnableTimer(Sender: TObject);
var
  Timer: TTimer;
  Button: TButton;
begin
  Timer := Sender as TTimer;
  Button := TButton(Timer.Tag);
  
  // เปิดการใช้งานปุ่มกลับ (ตรวจสอบสถานะ Database แทน WebSocket)
  if Assigned(Button) then
    Button.Enabled := FDatabaseConnected;
  
  // ทำลาย Timer และ clear reference
  if Timer = FButton1Timer then
  begin
    FButton1Timer.Free;
    FButton1Timer := nil;
  end
  else if Timer = FButton2Timer then
  begin
    FButton2Timer.Free;
    FButton2Timer := nil;
  end
  else if Timer = FButton3Timer then
  begin
    FButton3Timer.Free;
    FButton3Timer := nil;
  end
  else if Timer = FButton4Timer then
  begin
    FButton4Timer.Free;
    FButton4Timer := nil;
  end;
end;

procedure TMainForm.SendQueueCalledMessage(const QueueNumber, RoomName: string);
var
  JSONMessage, AllRoomsData, LongWaitData, LongWaitMessage: string;
  R, GrandTotalServed, GrandTotalWaiting: Integer;
  RTotal, RWaiting, RServed: array[1..4] of Integer;
begin
 GrandTotalServed  := 0;
 GrandTotalWaiting := 0;

  // Get stats for all rooms
  for R := 1 to 4 do
  begin
    RTotal[R]   := GetTotalQueues(R);
    RWaiting[R] := GetWaitingQueues(R);
    RServed[R]  := GetServedQueues(R);
    AddDebugLog(Format('Room %d: total=%d, waiting=%d, served=%d', [R, RTotal[R], RWaiting[R], RServed[R]]));
  end;

  // Build all_rooms array
  AllRoomsData := Format(
    '[{"room":1,"total":%d,"waiting":%d,"served":%d},' +
    '{"room":2,"total":%d,"waiting":%d,"served":%d},' +
    '{"room":3,"total":%d,"waiting":%d,"served":%d},' +
    '{"room":4,"total":%d,"waiting":%d,"served":%d}]',
    [RTotal[1], RWaiting[1], RServed[1], RTotal[2], RWaiting[2], RServed[2],
     RTotal[3], RWaiting[3], RServed[3], RTotal[4], RWaiting[4], RServed[4]]
  );
//
//  // สร้าง JSON message with stats
//  JSONMessage := Format(
//    '{"type":"call_queue","data":{"queue_number":"%s","counter":"%d","room_name":"%s","timestamp":"%s","all_rooms":%s}}',
//    [QueueNumber, FSelectedCounter, RoomName, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), AllRoomsData]
//  );

      GrandTotalServed := RServed[1] + RServed[2] + RServed[3] + RServed[4];
      GrandTotalWaiting := RWaiting[1] + RWaiting[2] + RWaiting[3] + RWaiting[4];
      // เพิ่มในข้อมูล JSON
      JSONMessage := Format(
        '{"type":"call_queue","data":{"queue_number":"%s","counter":"%d","room_name":"%s",' +
        '"timestamp":"%s","all_rooms":%s,"total_served":%d,"total_waiting":%d}}',
        [QueueNumber, FSelectedCounter, RoomName,
         FormatDateTime('yyyy-mm-dd hh:nn:ss', Now),
         AllRoomsData, GrandTotalServed, GrandTotalWaiting]
      );


  // ส่งผ่าน WebSocket ถ้าเชื่อมต่ออยู่
  if FWebSocketConnected then
  begin
    try
      sgcWebSocketClient1.WriteData(JSONMessage);
      AddDebugLog('>>> SENT call_queue: ' + QueueNumber + ' to counter ' + IntToStr(FSelectedCounter));
      
      // ส่งข้อมูลคิวรอนานแยกต่างหาก
      LongWaitData := GetLongWaitingQueues;
      if LongWaitData <> '[]' then
      begin
        LongWaitMessage := Format(
          '{"type":"long_waiting_queues","data":{"queues":%s,"timestamp":"%s"}}',
          [LongWaitData, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]
        );
        sgcWebSocketClient1.WriteData(LongWaitMessage);
        AddDebugLog('SENT long_waiting_queues: ' + LongWaitData);
      end;
    except
      on E: Exception do
      begin
        AddDebugLog('ERROR: Failed to send message - ' + E.Message);
      end;
    end;
  end
  else
  begin
    // เก็บข้อความไว้ใน offline queue
    FOfflineMessageQueue.Add(JSONMessage);
    AddDebugLog('OFFLINE: Queued message for ' + QueueNumber);
  end;
end;

procedure TMainForm.SendOfflineMessages;
var
  i: Integer;
  Message: string;
begin
  // ส่งข้อความที่เก็บไว้ทั้งหมดตามลำดับเวลา
  if FOfflineMessageQueue.Count > 0 then
  begin
    for i := 0 to FOfflineMessageQueue.Count - 1 do
    begin
      Message := FOfflineMessageQueue[i];
      try
        sgcWebSocketClient1.WriteData(Message);
      except
        on E: Exception do
        begin
          // Log error but continue with other messages
          // In production, this should be logged to a file
        end;
      end;
    end;
    
    // ล้างคิวหลังส่งเสร็จ
    FOfflineMessageQueue.Clear;
  end;
end;

procedure TMainForm.edtPriorityBarcodeInputKeyPress(Sender: TObject; var Key: Char);
var
  Barcode: string;
begin
  // เมื่อกด Enter ให้ประมวลผลบาร์โค้ดคิวรอนาน
  if Key = #13 then
  begin
    Key := #0; // ป้องกันเสียง beep
    Barcode := Trim(edtPriorityBarcodeInput.Text);
    
    if Barcode <> '' then
    begin
      ProcessPriorityBarcodeInput(Barcode);
      edtPriorityBarcodeInput.Clear; // ล้างช่องกรอกหลังประมวลผล
    end;
  end;
end;

procedure TMainForm.ProcessPriorityBarcodeInput(const Barcode: string);
var
  Query: TUniQuery;
  QueueNumber, RoomName: string;
begin
  // ตรวจสอบว่าเชื่อมต่อฐานข้อมูลหรือไม่
  if not FDatabaseConnected then
  begin
    ShowMessageAtForm('ไม่สามารถทำเครื่องหมายคิวรอนานได้: ไม่ได้เชื่อมต่อฐานข้อมูล');
    Exit;
  end;
  
  // ค้นหาคิวจากบาร์โค้ดและดึงข้อมูล
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := UniConnection1;
    Query.SQL.Text := 
      'SELECT qdisplay, room, fstatus, period, time_confirm FROM queue_data ' +
      'WHERE barcodes = :barcode';
    Query.ParamByName('barcode').AsString := Barcode;
    Query.Open;
    
    if Query.IsEmpty then
    begin
      ShowMessageAtForm('ไม่พบหมายเลขคิวในระบบ');
      Exit;
    end;

    // Check 1: Already Called
    if Query.FieldByName('fstatus').AsString = '1' then
    begin
       ShowMessageAtForm(Format('คิวนี้ถูกเรียกไปแล้ว เมื่อเวลา: %s', 
         [FormatDateTime('dd/mm/yyyy hh:nn:ss', Query.FieldByName('time_confirm').AsDateTime)]));
       Exit;
    end;

    // Check 2: Already Priority
    if Query.FieldByName('period').AsString = '1' then
    begin
       ShowMessageAtForm('คิวนี้ถูกกำหนดสถานะคิวรอนานไปแล้ว');
       Exit;
    end;
    
    // Check 3: Not Waiting (Safety check)
    if Query.FieldByName('fstatus').AsString <> '2' then
    begin
       ShowMessageAtForm('คิวนี้ไม่ได้อยู่ในสถานะรอเรียก (Status: ' + Query.FieldByName('fstatus').AsString + ')');
       Exit;
    end;
    
    QueueNumber := Query.FieldByName('qdisplay').AsString;
    case Query.FieldByName('room').AsInteger of
      1: RoomName := 'ยาปริมาณมาก';
      2: RoomName := 'ยาปริมาณน้อย';
      3: RoomName := 'กลับบ้านไม่มียา';
      4: RoomName := 'ยาขอก่อน';
    else
      RoomName := 'ไม่ทราบ';
    end;
  finally
    Query.Free;
  end;
  
  // แสดง confirm dialog พร้อมหมายเลขคิว
  if MessageDlgAtForm(
    Format('ทำเครื่องหมายคิวรอนาน'#13#10#13#10'คิว: %s'#13#10'ห้อง: %s'#13#10#13#10'ยืนยันหรือไม่?', 
      [QueueNumber, RoomName]),
    mtConfirmation, 
    [mbYes, mbNo]
  ) = mrYes then
  begin
    // ทำเครื่องหมายคิวรอนาน
    try
      MarkQueueAsPriority(Barcode);
      ShowMessageAtForm(Format('ทำเครื่องหมายคิวรอนานสำเร็จ'#13#10'คิว: %s', [QueueNumber]));
    except
      on E: Exception do
        ShowMessageAtForm('เกิดข้อผิดพลาด: ' + E.Message);
    end;
  end;
end;

procedure TMainForm.MarkQueueAsPriority(const Barcode: string);
var
  UpdateQuery: TUniQuery;
begin
  // อัพเดทฟิลด์ period เป็น "1" และบันทึก timestamp
  UpdateQuery := TUniQuery.Create(nil);
  try
    UpdateQuery.Connection := UniConnection1;
    UpdateQuery.SQL.Text := 
      'UPDATE queue_data ' +
      'SET period = ''1'', ' +
      '    timestamp = NOW() ' +
      'WHERE barcodes = :barcode';
    UpdateQuery.ParamByName('barcode').AsString := Barcode;
    UpdateQuery.Execute;
    
    // ส่งข้อความ WebSocket เพื่ออัพเดท priority queue list
    SendPriorityQueueUpdateMessage;
  finally
    UpdateQuery.Free;
  end;
end;

procedure TMainForm.SendPriorityQueueUpdateMessage;
var
  JSONMessage, LongWaitData, LongWaitMessage: string;
  Query: TUniQuery;
  PriorityQueues: string;
  i: Integer;
begin
  // Query คิวรอนาน 6 อันดับแรก
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := UniConnection1;
    Query.SQL.Text := 
      'SELECT qdisplay ' +
      'FROM queue_data ' +
      'WHERE period = ''1'' ' +
      'ORDER BY timestamp ASC ' +
      'LIMIT 6';
    Query.Open;
    
    // สร้าง array ของหมายเลขคิวรอนาน
    PriorityQueues := '[';
    i := 0;
    while not Query.Eof do
    begin
      if i > 0 then
        PriorityQueues := PriorityQueues + ',';
      PriorityQueues := PriorityQueues + '"' + Query.FieldByName('qdisplay').AsString + '"';
      Inc(i);
      Query.Next;
    end;
    PriorityQueues := PriorityQueues + ']';
    
    // สร้าง JSON message
    JSONMessage := Format(
      '{"type":"priority_queue","data":{"priority_queues":%s,"timestamp":"%s"}}',
      [PriorityQueues, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]
    );
    
    // ส่งผ่าน WebSocket ถ้าเชื่อมต่ออยู่
    if FWebSocketConnected then
    begin
      try
        sgcWebSocketClient1.WriteData(JSONMessage);
        AddDebugLog('SENT priority_queue: ' + PriorityQueues);
        
        // ส่งข้อมูลคิวรอนานด้วย
        LongWaitData := GetLongWaitingQueues;
        if LongWaitData <> '[]' then
        begin
          LongWaitMessage := Format(
            '{"type":"long_waiting_queues","data":{"queues":%s,"timestamp":"%s"}}',
            [LongWaitData, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]
          );
          sgcWebSocketClient1.WriteData(LongWaitMessage);
          AddDebugLog('SENT long_waiting_queues: ' + LongWaitData);
        end;
      except
        on E: Exception do
        begin
          AddDebugLog('ERROR: Failed to send priority message - ' + E.Message);
        end;
      end;
    end
    else
    begin
      // เก็บข้อความไว้ใน offline queue
      FOfflineMessageQueue.Add(JSONMessage);
      AddDebugLog('OFFLINE: Queued priority message');
    end;
  finally
    Query.Free;
  end;
end;

// ฟังก์ชันเรียกคิวด้วยตนเองตามประเภทบริการ
procedure TMainForm.CallNextQueueManually(RoomID: Integer);
var
  QueueNumber, QueueBarcode: string;
begin
  // ตรวจสอบว่าเชื่อมต่อฐานข้อมูลหรือไม่
  if not FDatabaseConnected then
  begin
    MessageDlgAtForm('ไม่สามารถเรียกคิวได้: ไม่ได้เชื่อมต่อฐานข้อมูล', mtWarning, [mbOK]);
    Exit;
  end;

  // ตรวจสอบว่าเลือกช่องบริการแล้วหรือไม่
  if FSelectedCounter = 0 then
  begin
    MessageDlgAtForm('กรุณาเลือกช่องบริการก่อนเรียกคิว', mtWarning, [mbOK]);
    Exit;
  end;
  
  // แจ้งเตือนถ้า WebSocket ไม่ได้เชื่อมต่อ (แต่ยังสามารถเรียกคิวได้)
  if not FWebSocketConnected then
  begin
    AddDebugLog('WARNING: WebSocket not connected - queue will be called but message may not be sent');
  end;

  // ค้นหาคิวถัดไปสำหรับประเภทบริการนี้
  if not GetNextQueueForRoom(RoomID, QueueNumber, QueueBarcode) then
  begin
    ShowMessageAtForm('ไม่มีคิวรอสำหรับประเภทบริการนี้');
    Exit;
  end;

  // อัพเดทสถานะคิว
  try
    UpdateQueueStatus(QueueBarcode);
    ShowMessageAtForm('เรียกคิว ' + QueueNumber + ' สำเร็จ');
  except
    on E: Exception do
      MessageDlgAtForm('เกิดข้อผิดพลาดในการเรียกคิว: ' + E.Message, mtError, [mbOK]);
  end;
end;

// ฟังก์ชันค้นหาคิวถัดไปที่ยังไม่ถูกเรียกสำหรับประเภทบริการที่กำหนด
// ฟังก์ชันค้นหาคิวถัดไปที่ยังไม่ถูกเรียกสำหรับประเภทบริการที่กำหนด (เฉพาะวันปัจจุบัน)
function TMainForm.GetNextQueueForRoom(RoomID: Integer; out QueueNumber: string; out QueueBarcode: string): Boolean;
var
  Query: TUniQuery;
begin
  Result := False;
  QueueNumber := '';
  QueueBarcode := '';
  
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := UniConnection1;
    Query.SQL.Text := 
      'SELECT qdisplay, barcodes ' +
      'FROM queue_data ' +
      'WHERE room = :room AND fstatus = ''2'' ' +
      'AND timestamp >= CURDATE() AND timestamp < CURDATE() + INTERVAL 1 DAY ' +  // เฉพาะวันปัจจุบัน
      'ORDER BY timestamp ASC ' +
      'LIMIT 1';
    Query.ParamByName('room').AsInteger := RoomID;
    Query.Open;
    
    if not Query.IsEmpty then
    begin
      QueueNumber := Query.FieldByName('qdisplay').AsString;
      QueueBarcode := Query.FieldByName('barcodes').AsString;
      Result := True;
    end;
  finally
    Query.Free;
  end;
end;

// Event handlers สำหรับปุ่มเรียกคิวแต่ละประเภท
procedure TMainForm.btnCallRoom1Click(Sender: TObject);
begin
  // ปิดปุ่มชั่วคราว 5 วินาที
  DisableButtonTemporarily(btnCallRoom1);
  // เรียกคิว "ยากลับบ้านมาก" (room = 1)
  CallNextQueueManually(1);
end;

procedure TMainForm.btnCallRoom2Click(Sender: TObject);
begin
  // ปิดปุ่มชั่วคราว 5 วินาที
  DisableButtonTemporarily(btnCallRoom2);
  // เรียกคิว "ยากลับบ้านน้อย" (room = 2)
  CallNextQueueManually(2);
end;

procedure TMainForm.btnCallRoom3Click(Sender: TObject);
begin
  // ปิดปุ่มชั่วคราว 5 วินาที
  DisableButtonTemporarily(btnCallRoom3);
  // เรียกคิว "กลับบ้านไม่มียา" (room = 3)
  CallNextQueueManually(3);
end;

procedure TMainForm.btnCallRoom4Click(Sender: TObject);
begin
  // ปิดปุ่มชั่วคราว 5 วินาที
  DisableButtonTemporarily(btnCallRoom4);
  // เรียกคิว "ยาขอก่อน" (room = 4)
  CallNextQueueManually(4);
end;

procedure TMainForm.btnConfigDragDrop(Sender, Source: TObject; X, Y: Integer);
begin

end;

// รีเฟรชข้อมูลสถานะคิวทั้งหมด
procedure TMainForm.RefreshQueueStatus;
begin
  try
    UpdateQueueStatusDisplay;
  except
    on E: Exception do
    begin
      AddDebugLog('[RefreshQueueStatus] Error: ' + E.Message);
      // บันทึก error แต่ไม่แสดงข้อความเพื่อไม่รบกวนการทำงาน
    end;
  end;
end;

// ดึงจำนวนคิวที่รออยู่สำหรับประเภทบริการที่กำหนด (เฉพาะวันปัจจุบัน)
function TMainForm.GetWaitingQueueCount(RoomID: Integer): Integer;
var  Query: TUniQuery;
begin
  Result := 0;

  if not UniConnection1.Connected then
    Exit;

  Query := TUniQuery.Create(nil);
  try
    try
      Query.Connection := UniConnection1;
      
      // ใช้ fstatus = '2' เหมือนกับ GetNextQueueNumber เพื่อความสอดคล้อง
      // และใช้ DATE() function เพื่อเปรียบเทียบเฉพาะวันที่
      Query.SQL.Text :=
        'SELECT COUNT(*) as queue_count ' +
        'FROM queue_data ' +
        'WHERE room = :room ' +
        'AND fstatus = ''2'' ' +
        'AND DATE(timestamp) = CURDATE()';
      Query.ParamByName('room').AsInteger := RoomID;
      
      AddDebugLog(Format('[GetWaitingQueueCount] SQL: %s, room=%d', [Query.SQL.Text, RoomID]));
      
      Query.Open;

      if not Query.IsEmpty then
      begin
        Result := Query.Fields[0].AsInteger;
        AddDebugLog(Format('[GetWaitingQueueCount] Result: %d for room %d', [Result, RoomID]));
      end
      else
        AddDebugLog(Format('[GetWaitingQueueCount] Query is empty for room %d', [RoomID]));
    except
      on E: Exception do
      begin
        AddDebugLog(Format('[GetWaitingQueueCount] Error for room %d: %s', [RoomID, E.Message]));
        Result := 0;
      end;
    end;
  finally
    Query.Free;
  end;
end;

// ดึงหมายเลขคิวถัดไปสำหรับประเภทบริการที่กำหนด (เฉพาะวันปัจจุบัน)
function TMainForm.GetNextQueueNumber(RoomID: Integer): string;
var
  Query: TUniQuery;
begin
  Result := '-';
  
  if not UniConnection1.Connected then
    Exit;

  Query := TUniQuery.Create(nil);
  try
    try
      Query.Connection := UniConnection1;
      Query.SQL.Text :=
        'SELECT qdisplay ' +
        'FROM queue_data ' +
        'WHERE room = :room AND fstatus = ''2'' ' +
        'AND DATE(timestamp) = CURDATE() ' +  // ใช้ DATE() เพื่อเปรียบเทียบวันที่เท่านั้น
        'ORDER BY timestamp ASC ' +
        'LIMIT 1';
      Query.ParamByName('room').AsInteger := RoomID;
      
      AddDebugLog(Format('[GetNextQueueNumber] SQL: %s, room=%d', [Query.SQL.Text, RoomID]));
      
      Query.Open;

      if not Query.IsEmpty then
      begin
        Result := Query.Fields[0].AsString;
        AddDebugLog(Format('[GetNextQueueNumber] Result: %s for room %d', [Result, RoomID]));
      end
      else
      begin
        AddDebugLog(Format('[GetNextQueueNumber] Query is empty for room %d', [RoomID]));
        // Debug: ตรวจสอบว่ามีข้อมูลในฐานข้อมูลหรือไม่
        Query.Close;
        Query.SQL.Text := 'SELECT COUNT(*) as total, DATE(timestamp) as date_val FROM queue_data WHERE room = :room AND fstatus = ''2'' GROUP BY DATE(timestamp)';
        Query.ParamByName('room').AsInteger := RoomID;
        Query.Open;
        while not Query.Eof do
        begin
          AddDebugLog(Format('[GetNextQueueNumber] Debug - Date: %s, Count: %d for room %d', 
            [Query.FieldByName('date_val').AsString, Query.FieldByName('total').AsInteger, RoomID]));
          Query.Next;
        end;
      end;
    except
      on E: Exception do
      begin
        AddDebugLog(Format('[GetNextQueueNumber] Error for room %d: %s', [RoomID, E.Message]));
        Result := '-';
      end;
    end;
  finally
    Query.Free;
  end;
end;

// อัพเดทการแสดงผลสถานะคิวบน UI
// อัพเดทการแสดงผลสถานะคิวบน caption ของปุ่ม
procedure TMainForm.UpdateQueueStatusDisplay;
var
  WaitingCount: Integer;
  NextQueue: string;
begin
  // ยากลับบ้านมาก (room = 1)
  WaitingCount := GetWaitingQueueCount(1);
  NextQueue    := GetNextQueueNumber(1);
  if Assigned(btnCallRoom1) then
    btnCallRoom1.Caption :=
      Format('ยามาก | รอ %d | ถัดไป %s', [WaitingCount, NextQueue]);

  // ยากลับบ้านน้อย (room = 2)
  WaitingCount := GetWaitingQueueCount(2);
  NextQueue    := GetNextQueueNumber(2);
  if Assigned(btnCallRoom2) then
    btnCallRoom2.Caption :=
      Format('ยาน้อย | รอ %d | ถัดไป %s', [WaitingCount, NextQueue]);

  // กลับบ้านไม่มียา (room = 3)
  WaitingCount := GetWaitingQueueCount(3);
  NextQueue    := GetNextQueueNumber(3);
  if Assigned(btnCallRoom3) then
    btnCallRoom3.Caption :=
      Format('ไม่มียา | รอ %d | ถัดไป %s', [WaitingCount, NextQueue]);

  // ยาขอก่อน (room = 4)
  WaitingCount := GetWaitingQueueCount(4);
  NextQueue    := GetNextQueueNumber(4);
  if Assigned(btnCallRoom4) then
    btnCallRoom4.Caption :=
      Format('ยาด่วน | รอ %d | ถัดไป %s', [WaitingCount, NextQueue]);
      
  AddDebugLog(Format('[UpdateQueueStatusDisplay] Updated - Room1: %d/%s, Room2: %d/%s, Room3: %d/%s, Room4: %d/%s', 
    [GetWaitingQueueCount(1), GetNextQueueNumber(1),
     GetWaitingQueueCount(2), GetNextQueueNumber(2), 
     GetWaitingQueueCount(3), GetNextQueueNumber(3),
     GetWaitingQueueCount(4), GetNextQueueNumber(4)]));
end;


// แสดงข้อมูลการจัดการวันใหม่
// หมายเหตุ: ระบบรีเซ็ตอัตโนมัติตาม design (ตรวจสอบวันที่ของคิวล่าสุด)
// ปุ่มนี้เป็นเพียงการแสดงข้อมูลและ refresh เท่านั้น
procedure TMainForm.btnResetDailyClick(Sender: TObject);
var
  LongWaitMessage, LongWaitData: string;
  I: Integer;
begin
  if not FWebSocketConnected then
  begin
    ShowMessageAtForm('WebSocket ไม่ได้เชื่อมต่อ');
    Exit;
  end;

  try
    // 1. Call Queue 1001 REMOVED as requested.
    
    // 2. Update Long Waiting (Show Complete List - 12 items)
    LongWaitData := '[';
    for I := 1 to 12 do
    begin
      if I > 1 then
        LongWaitData := LongWaitData + ',';
      // Simulate W-001 to W-012
      LongWaitData := LongWaitData + Format('{"queue":"W-%03d","room":%d}', [I, ((I - 1) mod 4) + 1]);
    end;
    LongWaitData := LongWaitData + ']';

    LongWaitMessage := Format(
      '{"type":"long_waiting_queues","data":{"queues":%s,"timestamp":"%s"}}',
      [LongWaitData, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]
    );
    sgcWebSocketClient1.WriteData(LongWaitMessage);
    AddDebugLog('SENT: 12 Long Waiting Queues (No Call)');

    ShowMessageAtForm('ส่งข้อมูลทดสอบคิวรอนานเรียบร้อย (ยกเลิกการเรียกคิว)');
    
  except
    on E: Exception do
      ShowMessageAtForm('เกิดข้อผิดพลาด: ' + E.Message);
  end;
end;

procedure TMainForm.btnTestSendClick(Sender: TObject);
var
  JSONMessage, AllRoomsData, LongWaitData, LongWaitMessage: string;
  I: Integer;
begin
  if not FWebSocketConnected then
  begin
    ShowMessageAtForm('WebSocket ไม่ได้เชื่อมต่อ');
    Exit;
  end;

  // ส่งข้อมูลตัวอย่างเต็มพื้นที่เพื่อดู layout

  // 1. ส่งสถิติทั้ง 4 ห้อง (แสดงเต็มพื้นที่)
  AllRoomsData := '[{"room":1,"total":45,"waiting":28,"served":17},' +
                  '{"room":2,"total":62,"waiting":35,"served":27},' +
                  '{"room":3,"total":18,"waiting":9,"served":9},' +
                  '{"room":4,"total":23,"waiting":15,"served":8}]';

  // 2. ส่งคิวทดสอบ 1001 ไปช่อง 5
  JSONMessage := Format(
    '{"type":"call_queue","data":{"queue_number":"1001","counter":"5","room_name":"ทดสอบ","timestamp":"%s","all_rooms":%s}}',
    [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), AllRoomsData]
  );
  
  try
    sgcWebSocketClient1.WriteData(JSONMessage);
    AddDebugLog('>>> TEST SENT: Queue 1001 to counter 5');

    ShowMessageAtForm('ส่งข้อมูลทดสอบสำเร็จ: คิว 1001 -> ช่อง 5');
  except
    on E: Exception do
    begin
      AddDebugLog('ERROR: ' + E.Message);
      ShowMessageAtForm('ส่งข้อมูลล้มเหลว: ' + E.Message);
    end;
  end;
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  S: string;
begin
  // Ctrl + D เพื่อแสดง Debug Memo
  if (ssCtrl in Shift) and (Key = Ord('D')) then
  begin
    S := '';
    if InputPassword('Admin Access', 'กรุณาใส่รหัสผ่าน:', S) then
    begin
      if S = 'super' then
      begin
        memoDebug.Visible     := True;
        memoDebug.Top         := FDebugMemoOriginalTop; // เลื่อนกลับมาตำแหน่งเดิม
        FbtnHideDebug.Visible := True;
        FbtnHideDebug.Top     := memoDebug.Top + 2; // ปรับตำแหน่งปุ่มตาม
        Self.Height           := FExpandedHeight; // ยืดฟอร์ม (562)
        memoDebug.BringToFront;
        FbtnHideDebug.BringToFront;
      end
      else
      begin
        ShowMessageAtForm('รหัสผ่านไม่ถูกต้อง');
      end;
    end;
  end;
end;

procedure TMainForm.btnHideDebugClick(Sender: TObject);
begin
  memoDebug.Visible := False;
  memoDebug.Top := 1000; // เลื่อนลงไปข้างล่าง
  FbtnHideDebug.Visible := False;
  Self.Height := FCollapsedHeight; // หดฟอร์ม (430)
end;

procedure TMainForm.btnPriorityBarcodeInputClick(Sender: TObject);
var  Barcode: string;
begin

    Barcode := Trim(edtPriorityBarcodeInput.Text);

    if Barcode <> '' then
    begin
      ProcessPriorityBarcodeInput(Barcode);
      edtPriorityBarcodeInput.Clear; // ล้างช่องกรอกหลังประมวลผล
    end;


end;

procedure TMainForm.Button1Click(Sender: TObject);
var 
  WaitingCount: Integer;
  NextQueue: string;
  Room: Integer;
  DebugMsg: string;
  Query: TUniQuery;
begin
  // Debug button - test queue display functions
  AddDebugLog('=== DEBUG: Testing Queue Display Functions ===');
  
  if not UniConnection1.Connected then
  begin
    AddDebugLog('ERROR: Database not connected');
    ShowMessageAtForm('Database not connected');
    Exit;
  end;
  
  // ตรวจสอบข้อมูลทั้งหมดในฐานข้อมูลก่อน (ไม่กรองวันที่)
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := UniConnection1;
    AddDebugLog('=== ข้อมูลทั้งหมดในฐานข้อมูล (ไม่กรองวันที่) ===');
    for Room := 1 to 4 do
    begin
      // นับคิวทั้งหมดที่มี fstatus = '2' (ไม่กรองวันที่)
      Query.Close;
      Query.SQL.Text := 'SELECT COUNT(*) as total FROM queue_data WHERE room = :room AND fstatus = ''2''';
      Query.ParamByName('room').AsInteger := Room;
      Query.Open;
      
      if not Query.IsEmpty then
        AddDebugLog(Format('Room %d: Total waiting queues (all dates) = %d', [Room, Query.FieldByName('total').AsInteger]));
      
      // หาคิวถัดไป (ไม่กรองวันที่)
      Query.Close;
      Query.SQL.Text := 'SELECT qdisplay FROM queue_data WHERE room = :room AND fstatus = ''2'' ORDER BY timestamp ASC LIMIT 1';
      Query.ParamByName('room').AsInteger := Room;
      Query.Open;
      
      if not Query.IsEmpty then
        AddDebugLog(Format('Room %d: Next queue (all dates) = %s', [Room, Query.FieldByName('qdisplay').AsString]))
      else
        AddDebugLog(Format('Room %d: No waiting queues found', [Room]));
    end;
  finally
    Query.Free;
  end;
  
  AddDebugLog('=== ทดสอบฟังก์ชันปกติ (กรองตามวันที่) ===');
  // Test all rooms with date filter
  for Room := 1 to 4 do
  begin
    WaitingCount := GetWaitingQueueCount(Room);
    NextQueue := GetNextQueueNumber(Room);
    
    DebugMsg := Format('Room %d: Waiting=%d, Next=%s', [Room, WaitingCount, NextQueue]);
    AddDebugLog(DebugMsg);
  end;
  
  // Force refresh the display
  AddDebugLog('=== Refreshing Queue Status Display ===');
  UpdateQueueStatusDisplay;
  
  AddDebugLog('=== DEBUG: Test Complete ===');
  
  // Show debug memo if hidden
  if not memoDebug.Visible then
  begin
    memoDebug.Visible := True;
    memoDebug.Top := FDebugMemoOriginalTop;
    FbtnHideDebug.Visible := True;
    Self.Height := FExpandedHeight;
  end;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  // บังคับซ่อนหน้าเริ่มต้นอีกครั้งในจังหวะ Show
  memoDebug.Visible := False;
  memoDebug.Top := 1000; // บังคับเลื่อนลง
  FbtnHideDebug.Visible := False;
  Self.Height := FCollapsedHeight;
end;

function TMainForm.InputPassword(const ACaption, APrompt: string; var AValue: string): Boolean;
var
  Form: TForm;
  PromptLabel: TLabel;
  Edit: TEdit;
  OkButton, CancelButton: TButton;
begin
  Result := False;
  Form := TForm.Create(nil);
  try
    Form.Caption := ACaption;
    Form.Width := 300;
    Form.Height := 150;
    Form.Position := poMainFormCenter;
    Form.BorderStyle := bsDialog;
    Form.PopupParent := Self;
    Form.PopupMode := pmAuto;
    
    PromptLabel := TLabel.Create(Form);
    PromptLabel.Parent := Form;
    PromptLabel.Caption := APrompt;
    PromptLabel.Left := 20;
    PromptLabel.Top := 20;
    
    Edit := TEdit.Create(Form);
    Edit.Parent := Form;
    Edit.Left := 20;
    Edit.Top := 45;
    Edit.Width := 250;
    Edit.PasswordChar := '*';
    Edit.Text := AValue;
    
    OkButton := TButton.Create(Form);
    OkButton.Parent := Form;
    OkButton.Caption := 'OK';
    OkButton.Default := True;
    OkButton.ModalResult := mrOk;
    OkButton.Left := 110;
    OkButton.Top := 80;
    
    CancelButton := TButton.Create(Form);
    CancelButton.Parent := Form;
    CancelButton.Caption := 'Cancel';
    CancelButton.Cancel := True;
    CancelButton.ModalResult := mrCancel;
    CancelButton.Left := 195;
    CancelButton.Top := 80;
    
    if Form.ShowModal = mrOk then
    begin
      AValue := Edit.Text;
      Result := True;
    end;
  finally
    Form.Free;
  end;
end;

end.
