unit ReconnectFormU;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TReconnectForm = class(TForm)
    lblStatus: TLabel;
    lblCountdown: TLabel;
    lblRetry: TLabel;
    ProgressTimer: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure ProgressTimerTimer(Sender: TObject);
  private
    FDots: Integer;
    FRetryCount: Integer;
    FMaxRetries: Integer;
    FCountdown: Integer;
    procedure UpdateDisplay;
  public
    procedure SetRetryInfo(ARetryCount, AMaxRetries, ACountdown: Integer);
  end;

implementation

{$R *.dfm}

procedure TReconnectForm.FormCreate(Sender: TObject);
begin
  FDots := 0;
  FRetryCount := 0;
  FMaxRetries := 10;
  FCountdown := 5;
  ProgressTimer.Interval := 500;
  ProgressTimer.Enabled := True;
  UpdateDisplay;
end;

procedure TReconnectForm.ProgressTimerTimer(Sender: TObject);
begin
  Inc(FDots);
  if FDots > 3 then
    FDots := 0;
  UpdateDisplay;
end;

procedure TReconnectForm.UpdateDisplay;
var
  Dots: string;
begin
  case FDots of
    0: Dots := '';
    1: Dots := '.';
    2: Dots := '..';
    3: Dots := '...';
  end;
  
  if Assigned(lblStatus) then
  begin
    lblStatus.Caption := 'Reconnecting' + Dots;
    lblStatus.Refresh;
  end;
  
  if Assigned(lblRetry) then
  begin
    lblRetry.Caption := Format('Attempt: %d/%d', [FRetryCount, FMaxRetries]);
    lblRetry.Refresh;
  end;
  
  if Assigned(lblCountdown) then
  begin
    if FCountdown > 1 then
      lblCountdown.Caption := Format('Next retry in %d seconds', [FCountdown])
    else if FCountdown = 1 then
      lblCountdown.Caption := 'Next retry in 1 second'
    else
      lblCountdown.Caption := 'Connecting now...';
    lblCountdown.Refresh;
  end;
  
  Application.ProcessMessages;
end;

procedure TReconnectForm.SetRetryInfo(ARetryCount, AMaxRetries, ACountdown: Integer);
begin
  FRetryCount := ARetryCount;
  FMaxRetries := AMaxRetries;
  FCountdown := ACountdown;
  UpdateDisplay;
  lblRetry.Refresh;
  lblCountdown.Refresh;
  lblStatus.Refresh;
  Application.ProcessMessages;
end;

end.
