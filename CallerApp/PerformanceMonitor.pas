unit PerformanceMonitor;

interface

uses
  System.SysUtils, System.Classes, System.Diagnostics, System.Generics.Collections,
  ErrorLogger;

type
  TPerformanceMetric = record
    OperationName: string;
    StartTime: TDateTime;
    ElapsedMs: Int64;
    Success: Boolean;
    ErrorMessage: string;
  end;

  TPerformanceMonitor = class
  private
    FMetrics: TList<TPerformanceMetric>;
    FActiveOperations: TDictionary<string, TStopwatch>;
    class var FInstance: TPerformanceMonitor;
    constructor Create;
  public
    destructor Destroy; override;
    class function Instance: TPerformanceMonitor;
    
    procedure StartOperation(const OperationName: string);
    procedure EndOperation(const OperationName: string; Success: Boolean = True; const ErrorMessage: string = '');
    procedure LogInstantMetric(const OperationName: string; ElapsedMs: Int64; Success: Boolean = True);
    
    function GetAverageTime(const OperationName: string): Double;
    function GetOperationCount(const OperationName: string): Integer;
    function GetSuccessRate(const OperationName: string): Double;
    procedure GetPerformanceReport(Report: TStrings);
    procedure ClearMetrics;
  end;

implementation

{ TPerformanceMonitor }

constructor TPerformanceMonitor.Create;
begin
  inherited;
  FMetrics := TList<TPerformanceMetric>.Create;
  FActiveOperations := TDictionary<string, TStopwatch>.Create;
end;

destructor TPerformanceMonitor.Destroy;
var
  Stopwatch: TStopwatch;
begin
  // Stop any active operations
  for Stopwatch in FActiveOperations.Values do
    Stopwatch.Stop;
    
  FActiveOperations.Free;
  FMetrics.Free;
  FInstance := nil;
  inherited;
end;

class function TPerformanceMonitor.Instance: TPerformanceMonitor;
begin
  if not Assigned(FInstance) then
    FInstance := TPerformanceMonitor.Create;
  Result := FInstance;
end;

procedure TPerformanceMonitor.StartOperation(const OperationName: string);
var
  Stopwatch: TStopwatch;
begin
  // Stop existing operation with same name if any
  if FActiveOperations.ContainsKey(OperationName) then
  begin
    FActiveOperations[OperationName].Stop;
    FActiveOperations.Remove(OperationName);
  end;
  
  Stopwatch := TStopwatch.StartNew;
  FActiveOperations.Add(OperationName, Stopwatch);
end;

procedure TPerformanceMonitor.EndOperation(const OperationName: string; Success: Boolean; const ErrorMessage: string);
var
  Stopwatch: TStopwatch;
  Metric: TPerformanceMetric;
begin
  if not FActiveOperations.TryGetValue(OperationName, Stopwatch) then
    Exit; // Operation not found
    
  Stopwatch.Stop;
  
  Metric.OperationName := OperationName;
  Metric.StartTime := Now - (Stopwatch.ElapsedMilliseconds / MSecsPerDay);
  Metric.ElapsedMs := Stopwatch.ElapsedMilliseconds;
  Metric.Success := Success;
  Metric.ErrorMessage := ErrorMessage;
  
  FMetrics.Add(Metric);
  FActiveOperations.Remove(OperationName);
  
  // Log performance metric
  TErrorLogger.Instance.LogPerformance(OperationName, Metric.ElapsedMs, 'PERFORMANCE');
  
  // Log error if operation failed
  if not Success and (ErrorMessage <> '') then
    TErrorLogger.Instance.LogMessage(Format('Operation failed: %s - %s', [OperationName, ErrorMessage]), llError, 'PERFORMANCE');
end;

procedure TPerformanceMonitor.LogInstantMetric(const OperationName: string; ElapsedMs: Int64; Success: Boolean);
var
  Metric: TPerformanceMetric;
begin
  Metric.OperationName := OperationName;
  Metric.StartTime := Now;
  Metric.ElapsedMs := ElapsedMs;
  Metric.Success := Success;
  Metric.ErrorMessage := '';
  
  FMetrics.Add(Metric);
  TErrorLogger.Instance.LogPerformance(OperationName, ElapsedMs, 'PERFORMANCE');
end;

function TPerformanceMonitor.GetAverageTime(const OperationName: string): Double;
var
  Metric: TPerformanceMetric;
  Total: Int64;
  Count: Integer;
begin
  Total := 0;
  Count := 0;
  
  for Metric in FMetrics do
  begin
    if SameText(Metric.OperationName, OperationName) then
    begin
      Inc(Total, Metric.ElapsedMs);
      Inc(Count);
    end;
  end;
  
  if Count > 0 then
    Result := Total / Count
  else
    Result := 0;
end;

function TPerformanceMonitor.GetOperationCount(const OperationName: string): Integer;
var
  Metric: TPerformanceMetric;
begin
  Result := 0;
  for Metric in FMetrics do
  begin
    if SameText(Metric.OperationName, OperationName) then
      Inc(Result);
  end;
end;

function TPerformanceMonitor.GetSuccessRate(const OperationName: string): Double;
var
  Metric: TPerformanceMetric;
  Total, Successful: Integer;
begin
  Total := 0;
  Successful := 0;
  
  for Metric in FMetrics do
  begin
    if SameText(Metric.OperationName, OperationName) then
    begin
      Inc(Total);
      if Metric.Success then
        Inc(Successful);
    end;
  end;
  
  if Total > 0 then
    Result := (Successful / Total) * 100
  else
    Result := 0;
end;

procedure TPerformanceMonitor.GetPerformanceReport(Report: TStrings);
var
  Operations: TStringList;
  Operation: string;
  AvgTime: Double;
  Count: Integer;
  SuccessRate: Double;
begin
  Report.Clear;
  Report.Add('=== Performance Report ===');
  Report.Add(Format('Generated: %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]));
  Report.Add(Format('Total Metrics: %d', [FMetrics.Count]));
  Report.Add('');
  
  // Get unique operation names
  Operations := TStringList.Create;
  try
    Operations.Duplicates := dupIgnore;
    Operations.Sorted := True;
    
    for var Metric in FMetrics do
      Operations.Add(Metric.OperationName);
    
    // Generate report for each operation
    for Operation in Operations do
    begin
      AvgTime := GetAverageTime(Operation);
      Count := GetOperationCount(Operation);
      SuccessRate := GetSuccessRate(Operation);
      
      Report.Add(Format('Operation: %s', [Operation]));
      Report.Add(Format('  Count: %d', [Count]));
      Report.Add(Format('  Average Time: %.2f ms', [AvgTime]));
      Report.Add(Format('  Success Rate: %.1f%%', [SuccessRate]));
      Report.Add('');
    end;
    
  finally
    Operations.Free;
  end;
end;

procedure TPerformanceMonitor.ClearMetrics;
begin
  FMetrics.Clear;
end;

end.