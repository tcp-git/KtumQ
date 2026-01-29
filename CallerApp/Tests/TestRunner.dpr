program TestRunner;

{$APPTYPE CONSOLE}

uses
  TestFramework,
  GUITestRunner,
  TextTestRunner,
  QueueControllerTests in 'QueueControllerTests.pas',
  IntegrationTests in 'IntegrationTests.pas',
  SystemTests in 'SystemTests.pas',
  QueueController in '..\QueueController.pas',
  DatabaseManager in '..\DatabaseManager.pas',
  WebSocketManager in '..\WebSocketManager.pas',
  ErrorLogger in '..\ErrorLogger.pas',
  PerformanceMonitor in '..\PerformanceMonitor.pas';

begin
  if IsConsole then
    TextTestRunner.RunRegisteredTests
  else
    GUITestRunner.RunRegisteredTests;
end.