program CallerApp;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {frmMain},
  DatabaseManager in 'DatabaseManager.pas',
  WebSocketManager in 'WebSocketManager.pas',
  QueueController in 'QueueController.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.