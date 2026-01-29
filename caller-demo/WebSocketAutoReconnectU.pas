unit WebSocketAutoReconnectU;

interface

uses
  System.SysUtils, System.Classes, Vcl.ExtCtrls, Vcl.Dialogs,
  sgcWebSocket, sgcWebSocket_Classes, sgcWebSocket_Client;

type
  TConnectionStatus = (csDisconnected, csConnecting, csConnected, csError);
  TStatusUpdateEvent = procedure(const AMessage: string; ACountdown: Integer) of object;
  TShowModalEvent = procedure(ARetryCount, AMaxRetries, ACountdown: Integer) of object;
  THideModalEvent = procedure of object;
  
  TWebSocketAutoReconnect = class
  private
    FClient: TsgcWebSocketClient;
    FReconnectTimer: TTimer;
    FCountdownTimer: TTimer;
    FStatus: TConnectionStatus;
    FReconnectInterval: Integer;
    FMaxRetries: Integer;
    FRetryCount: Integer;
    FCountdown: Integer;
    FOnStatusChange: TNotifyEvent;
    FOnStatusUpdate: TStatusUpdateEvent;
    FOnShowModal: TShowModalEvent;
    FOnHideModal: THideModalEvent;
    
    procedure OnTimerReconnect(Sender: TObject);
    procedure OnTimerCountdown(Sender: TObject);
    procedure SetStatus(AStatus: TConnectionStatus);
    procedure UpdateStatus;
    
  public
    constructor Create(AClient: TsgcWebSocketClient);
    destructor Destroy; override;
    
    procedure Connect;
    procedure Disconnect;
    procedure StartAutoReconnect;
    procedure StopAutoReconnect;
    function GetStatusText: string;
    procedure ShowMessageAtActiveForm(const Msg: string);
    
    property Status: TConnectionStatus read FStatus;
    property RetryCount: Integer read FRetryCount;
    property Countdown: Integer read FCountdown;
    property ReconnectInterval: Integer read FReconnectInterval write FReconnectInterval;
    property MaxRetries: Integer read FMaxRetries write FMaxRetries;
    property OnStatusChange: TNotifyEvent read FOnStatusChange write FOnStatusChange;
    property OnStatusUpdate: TStatusUpdateEvent read FOnStatusUpdate write FOnStatusUpdate;
    property OnShowModal: TShowModalEvent read FOnShowModal write FOnShowModal;
    property OnHideModal: THideModalEvent read FOnHideModal write FOnHideModal;
  end;

implementation

constructor TWebSocketAutoReconnect.Create(AClient: TsgcWebSocketClient);
begin
  inherited Create;
  FClient := AClient;
  FStatus := csDisconnected;
  FReconnectInterval := 5000;
  FMaxRetries := 10;
  FRetryCount := 0;
  FCountdown := 0;
  
  FReconnectTimer := TTimer.Create(nil);
  FReconnectTimer.Enabled := False;
  FReconnectTimer.Interval := FReconnectInterval;
  FReconnectTimer.OnTimer := OnTimerReconnect;
  
  FCountdownTimer := TTimer.Create(nil);
  FCountdownTimer.Enabled := False;
  FCountdownTimer.Interval := 1000;
  FCountdownTimer.OnTimer := OnTimerCountdown;
end;

destructor TWebSocketAutoReconnect.Destroy;
begin
  StopAutoReconnect;
  FCountdownTimer.Free;
  FReconnectTimer.Free;
  inherited;
end;

procedure TWebSocketAutoReconnect.SetStatus(AStatus: TConnectionStatus);
begin
  if FStatus <> AStatus then
  begin
    FStatus := AStatus;
    UpdateStatus;
    if Assigned(FOnStatusChange) then
      FOnStatusChange(Self);
  end;
end;

procedure TWebSocketAutoReconnect.UpdateStatus;
begin
  if Assigned(FOnStatusUpdate) then
    FOnStatusUpdate(GetStatusText, FCountdown);
end;

function TWebSocketAutoReconnect.GetStatusText: string;
begin
  case FStatus of
    csConnected: Result := 'Connected';
    csConnecting: Result := Format('Connecting... (%d/%d)', [FRetryCount, FMaxRetries]);
    csError: Result := Format('Failed (%d/%d)', [FRetryCount, FMaxRetries]);
    csDisconnected: Result := 'Disconnected';
  end;
end;

procedure TWebSocketAutoReconnect.Connect;
begin
  if not Assigned(FClient) then
    Exit;
    
  try
    SetStatus(csConnecting);
    if not FClient.Active then
      FClient.Active := True;
  except
    on E: Exception do
    begin
      SetStatus(csError);
      StartAutoReconnect;
    end;
  end;
end;

procedure TWebSocketAutoReconnect.Disconnect;
begin
  StopAutoReconnect;
  if Assigned(FClient) and FClient.Active then
  begin
    FClient.Active := False;
    SetStatus(csDisconnected);
  end;
end;

procedure TWebSocketAutoReconnect.StartAutoReconnect;
begin
  if FRetryCount >= FMaxRetries then
  begin
    if Assigned(FOnHideModal) then
      FOnHideModal;
    ShowMessageAtActiveForm(Format('Cannot connect to WebSocket after %d attempts'#13#10 +
      'Please check:'#13#10 +
      '- WebSocket Server is running'#13#10 +
      '- Host and Port settings are correct', [FMaxRetries]));
    Exit;
  end;
  
  Inc(FRetryCount);
  FCountdown := FReconnectInterval div 1000;
  FReconnectTimer.Enabled := True;
  FCountdownTimer.Enabled := True;
  
  if Assigned(FOnShowModal) then
    FOnShowModal(FRetryCount, FMaxRetries, FCountdown);
    
  UpdateStatus;
end;

procedure TWebSocketAutoReconnect.StopAutoReconnect;
begin
  FReconnectTimer.Enabled := False;
  FCountdownTimer.Enabled := False;
  FRetryCount := 0;
  FCountdown := 0;
  
  if Assigned(FOnHideModal) then
    FOnHideModal;
end;

procedure TWebSocketAutoReconnect.OnTimerCountdown(Sender: TObject);
begin
  Dec(FCountdown);
  if FCountdown < 0 then
    FCountdown := 0;
    
  if Assigned(FOnShowModal) then
    FOnShowModal(FRetryCount, FMaxRetries, FCountdown);
    
  UpdateStatus;
end;

procedure TWebSocketAutoReconnect.OnTimerReconnect(Sender: TObject);
begin
  FCountdownTimer.Enabled := False;
  
  if FRetryCount > FMaxRetries then
  begin
    StopAutoReconnect;
    ShowMessageAtActiveForm(Format('Cannot connect to WebSocket after %d attempts'#13#10 +
      'Please check:'#13#10 +
      '- WebSocket Server is running'#13#10 +
      '- Host and Port settings are correct', [FMaxRetries]));
    Exit;
  end;
  
  if Assigned(FClient) and not FClient.Active then
    Connect;
end;

procedure TWebSocketAutoReconnect.ShowMessageAtActiveForm(const Msg: string);
var
  MsgForm: TForm;
  ActiveForm: TForm;
begin
  ActiveForm := Screen.ActiveForm;
  MsgForm := CreateMessageDialog(Msg, mtInformation, [mbOK]);
  try
    if Assigned(ActiveForm) and ActiveForm.Visible then
    begin
      MsgForm.Position := poDesigned;
      MsgForm.Left := ActiveForm.Left + (ActiveForm.Width - MsgForm.Width) div 2;
      MsgForm.Top := ActiveForm.Top + (ActiveForm.Height - MsgForm.Height) div 2;
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

end.
