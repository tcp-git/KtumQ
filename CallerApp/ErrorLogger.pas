unit ErrorLogger;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.DateUtils, System.StrUtils, Winapi.Windows;

type
  TLogLevel = (llDebug, llInfo, llWarning, llError, llCritical);
  
  TErrorLogger = class
  private
    FLogFile: string;
    FMaxLogSize: Int64;
    FMaxLogFiles: Integer;
    class var FInstance: TErrorLogger;
    constructor Create;
    procedure RotateLogFiles;
    function GetLogLevelString(Level: TLogLevel): string;
  public
    destructor Destroy; override;
    class function Instance: TErrorLogger;
    
    procedure LogMessage(const Message: string; Level: TLogLevel = llInfo; const Component: string = '');
    procedure LogException(E: Exception; const Context: string = ''; const Component: string = '');
    procedure LogPerformance(const Operation: string; ElapsedMs: Int64; const Component: string = '');
    procedure LogConnectionEvent(const Event: string; const Details: string = '');
    
    property LogFile: string read FLogFile write FLogFile;
    property MaxLogSize: Int64 read FMaxLogSize write FMaxLogSize;
    property MaxLogFiles: Integer read FMaxLogFiles write FMaxLogFiles;
  end;

implementation

{ TErrorLogger }

constructor TErrorLogger.Create;
begin
  inherited;
  FLogFile := ExtractFilePath(ParamStr(0)) + 'queue_system.log';
  FMaxLogSize := 10 * 1024 * 1024; // 10MB
  FMaxLogFiles := 5;
end;

destructor TErrorLogger.Destroy;
begin
  FInstance := nil;
  inherited;
end;

class function TErrorLogger.Instance: TErrorLogger;
begin
  if not Assigned(FInstance) then
    FInstance := TErrorLogger.Create;
  Result := FInstance;
end;

procedure TErrorLogger.RotateLogFiles;
var
  i: Integer;
  OldFile, NewFile: string;
  FileHandle: THandle;
  FileSize: Int64;
begin
  if not FileExists(FLogFile) then Exit;
  
  // Check if rotation is needed using FileSize
  try
    FileHandle := FileOpen(FLogFile, fmOpenRead or fmShareDenyNone);
    if FileHandle <> INVALID_HANDLE_VALUE then
    begin
      FileSize := FileSeek(FileHandle, 0, 2); // Seek to end to get size
      FileClose(FileHandle);
      if FileSize < FMaxLogSize then Exit;
    end
    else
      Exit;
  except
    Exit; // If we can't get file size, don't rotate
  end;
  
  try
    // Delete oldest log file
    OldFile := ChangeFileExt(FLogFile, Format('.%d.log', [FMaxLogFiles - 1]));
    if FileExists(OldFile) then
      DeleteFile(PWideChar(OldFile));
    
    // Rotate existing log files
    for i := FMaxLogFiles - 2 downto 1 do
    begin
      OldFile := ChangeFileExt(FLogFile, Format('.%d.log', [i]));
      NewFile := ChangeFileExt(FLogFile, Format('.%d.log', [i + 1]));
      if FileExists(OldFile) then
        RenameFile(PWideChar(OldFile), PWideChar(NewFile));
    end;
    
    // Move current log to .1.log
    NewFile := ChangeFileExt(FLogFile, '.1.log');
    RenameFile(PWideChar(FLogFile), PWideChar(NewFile));
    
  except
    // Silently handle rotation errors to prevent logging from failing
  end;
end;

function TErrorLogger.GetLogLevelString(Level: TLogLevel): string;
begin
  case Level of
    llDebug: Result := 'DEBUG';
    llInfo: Result := 'INFO';
    llWarning: Result := 'WARN';
    llError: Result := 'ERROR';
    llCritical: Result := 'CRITICAL';
  else
    Result := 'UNKNOWN';
  end;
end;

procedure TErrorLogger.LogMessage(const Message: string; Level: TLogLevel; const Component: string);
var
  LogEntry: string;
  LogStream: TFileStream;
  LogBytes: TBytes;
begin
  try
    RotateLogFiles;
    
    LogEntry := Format('[%s] [%s] %s: %s%s', [
      FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now),
      GetLogLevelString(Level),
      IfThen(Component <> '', Component, 'SYSTEM'),
      Message,
      sLineBreak
    ]);
    
    LogBytes := TEncoding.UTF8.GetBytes(LogEntry);
    
    if FileExists(FLogFile) then
      LogStream := TFileStream.Create(FLogFile, fmOpenWrite or fmShareDenyWrite)
    else
      LogStream := TFileStream.Create(FLogFile, fmCreate or fmShareDenyWrite);
      
    try
      LogStream.Seek(0, soEnd);
      LogStream.WriteBuffer(LogBytes[0], Length(LogBytes));
    finally
      LogStream.Free;
    end;
    
  except
    // Silently handle logging errors to prevent infinite recursion
  end;
end;

procedure TErrorLogger.LogException(E: Exception; const Context: string; const Component: string);
var
  Message: string;
begin
  Message := Format('Exception: %s', [E.Message]);
  if Context <> '' then
    Message := Message + Format(' (Context: %s)', [Context]);
    
  LogMessage(Message, llError, Component);
end;

procedure TErrorLogger.LogPerformance(const Operation: string; ElapsedMs: Int64; const Component: string);
var
  Message: string;
  Level: TLogLevel;
begin
  Message := Format('Performance: %s took %d ms', [Operation, ElapsedMs]);
  
  // Determine log level based on elapsed time
  if ElapsedMs > 5000 then
    Level := llWarning
  else if ElapsedMs > 1000 then
    Level := llInfo
  else
    Level := llDebug;
    
  LogMessage(Message, Level, Component);
end;

procedure TErrorLogger.LogConnectionEvent(const Event: string; const Details: string);
var
  Message: string;
begin
  Message := Format('Connection: %s', [Event]);
  if Details <> '' then
    Message := Message + Format(' (%s)', [Details]);
    
  LogMessage(Message, llInfo, 'CONNECTION');
end;

end.