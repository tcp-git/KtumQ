program TerminalApp;

uses
  Vcl.Forms,
  DisplayForm in 'DisplayForm.pas' {frmDisplay},
  WebSocketClientManager in 'WebSocketClientManager.pas',
  DisplayController in 'DisplayController.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmDisplay, frmDisplay);
  Application.Run;
end.