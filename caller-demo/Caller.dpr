program Caller;

uses
  Vcl.Forms,
  MainFormU in 'MainFormU.pas' {MainForm},
  ConfigFormU in 'ConfigFormU.pas' {ConfigForm},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Light');
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
