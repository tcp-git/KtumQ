unit ErrorLogger;

interface

uses
  System.SysUtils, System.Classes, System.IniFiles, Winapi.Windows;

type
  TErrorLogger = class
  private
    FLogFileName: string;
    FMaxLogSize: Integer;
    FEnabled: Boolean;
    procedure RotateLogFile;
    function GetLogFileName: string;
  public
    constructor Create(const LogFileName: string = '');
    destructor Destroy; override;
    
    procedure LogError(const ErrorMsg: string; const ErrorType: string = 'ERROR');
    procedure LogInfo(const InfoMsg: string);
    procedure LogWarning(const WarningMsg: string);
    procedure LogDebug(const DebugMsg: string);
    
    procedure EnableLogging(Enabled: Boolean);
    procedure SetMaxLogSize(MaxSize: Integer);
    procedure ClearLog;
    
    property LogFileName: string read FLogFileName;
    property Enabled: Boolean read FEnabled write FEnabled;
  end;

var
  GlobalErrorLogger: TErrorLogger;

implementation

constructor TErrorLogger.Create(const LogFileName: string);
begin
  inherited Create;
  
  if LogFileName <> '' then
    FLogFileName := LogFileName
  else
    FLogFileName := GetLogFileName;
    
  FMaxLogSize := 1024 * 1024; // 1MB default
  FEnabled := True;
end;

destructor TErrorLogger.Destroy;
begin
  inherited;
end;

function TErrorLogger.GetLogFileName: string;
var
  AppPath: string;
begin
  AppPath := ExtractFilePath(ParamStr(0));
  Result := AppPath + 'terminal_error.log';
end;

procedure TErrorLogger.LogError(const ErrorMsg: string; const ErrorType: string);
var
  LogFile: TextFile;
  LogEntry: string;
begin
  if not FEnabled then Exit;
  
  try
    // Check if log file needs rotation
    if FileExists(FLogFileName) then
    begin
      if FileSize(FLogFileName) > FMaxLogSize then
        RotateLogFile;
    end;
    
    LogEntry := Format('[%s] %s: %s', 
      [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), ErrorType, ErrorMsg]);
    
    AssignFile(LogFile, FLogFileName);
    if FileExists(FLogFileName) then
      Append(LogFile)
    else
      Rewrite(LogFile);
      
    try
      Writeln(LogFile, LogEntry);
    finally
      CloseFile(LogFile);
    end;
    
    // Also output to debug console
    OutputDebugString(PChar(LogEntry));
    
  except
    // Silently ignore logging errors to prevent infinite loops
  end;
end;

procedure TErrorLogger.LogInfo(const InfoMsg: string);
begin
  LogError(InfoMsg, 'INFO');
end;

procedure TErrorLogger.LogWarning(const WarningMsg: string);
begin
  LogError(WarningMsg, 'WARNING');
end;

procedure TErrorLogger.LogDebug(const DebugMsg: string);
begin
  LogError(DebugMsg, 'DEBUG');
end;

procedure TErrorLogger.EnableLogging(Enabled: Boolean);
begin
  FEnabled := Enabled;
end;

procedure TErrorLogger.SetMaxLogSize(MaxSize: Integer);
begin
  if MaxSize > 0 then
    FMaxLogSize := MaxSize;
end;

procedure TErrorLogger.ClearLog;
var
  LogFile: TextFile;
begin
  if not FEnabled then Exit;
  
  try
    if FileExists(FLogFileName) then
    begin
      AssignFile(LogFile, FLogFileName);
      Rewrite(LogFile);
      CloseFile(LogFile);
    end;
  except
    // Silently ignore errors
  end;
end;

procedure TErrorLogger.RotateLogFile;
var
  BackupFileName: string;
begin
  try
    BackupFileName := ChangeFileExt(FLogFileName, '.bak');
    
    // Delete old backup if exists
    if FileExists(BackupFileName) then
      DeleteFile(PWideChar(BackupFileName));
      
    // Rename current log to backup
    if FileExists(FLogFileName) then
      RenameFile(PWideChar(FLogFileName), PWideChar(BackupFileName));
      
  except
    // Silently ignore rotation errors
  end;
end;

function FileSize(const FileName: string): Int64;
var
  SearchRec: TSearchRec;
begin
  Result := 0;
  if FindFirst(FileName, faAnyFile, SearchRec) = 0 then
  begin
    Result := SearchRec.Size;
    FindClose(SearchRec);
  end;
end;

initialization
  GlobalErrorLogger := TErrorLogger.Create;

finalization
  GlobalErrorLogger.Free;

end.