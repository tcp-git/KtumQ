unit DisplayController;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.Generics.Collections;

type
  TDisplayController = class
  private
    FDisplayForm: TObject; // Changed from TfrmDisplay to TObject
    FCurrentQueues: TList<string>;
    FBlinkingQueues: TList<string>;
  public
    constructor Create(DisplayForm: TObject); // Changed parameter type
    destructor Destroy; override;
    
    procedure ProcessMessage(const JsonMessage: string);
    procedure UpdateDisplay(const QueueNumbers: TArray<string>; const IsNew: TArray<Boolean>);
    procedure BlinkNewNumbers(const QueueNumbers: TArray<string>);
    procedure ManageScrollingText(const Text: string);
    procedure SendDisplayResponse(const QueueNumbers: TArray<string>);
    
    property CurrentQueues: TList<string> read FCurrentQueues;
  end;

implementation

uses
  DisplayForm;

constructor TDisplayController.Create(DisplayForm: TObject);
begin
  inherited Create;
  FDisplayForm := DisplayForm;
  FCurrentQueues := TList<string>.Create;
  FBlinkingQueues := TList<string>.Create;
end;

destructor TDisplayController.Destroy;
begin
  FBlinkingQueues.Free;
  FCurrentQueues.Free;
  inherited;
end;

procedure TDisplayController.ProcessMessage(const JsonMessage: string);
var
  JsonObj: TJSONObject;
  DataObj: TJSONObject;
  QueueArray: TJSONArray;
  IsNewArray: TJSONArray;
  QueueNumbers: TArray<string>;
  IsNew: TArray<Boolean>;
  i: Integer;
  MessageType: string;
  ScrollingText: string;
begin
  try
    JsonObj := TJSONObject.ParseJSONValue(JsonMessage) as TJSONObject;
    if not Assigned(JsonObj) then Exit;
    
    try
      MessageType := JsonObj.GetValue('type').Value;
      
      if MessageType = 'queue_call' then
      begin
        DataObj := JsonObj.GetValue('data') as TJSONObject;
        if not Assigned(DataObj) then Exit;
        
        // Parse queue numbers
        QueueArray := DataObj.GetValue('queue_numbers') as TJSONArray;
        if Assigned(QueueArray) then
        begin
          SetLength(QueueNumbers, QueueArray.Count);
          for i := 0 to QueueArray.Count - 1 do
            QueueNumbers[i] := QueueArray.Items[i].Value;
        end;
        
        // Parse is_new flags
        IsNewArray := DataObj.GetValue('is_new') as TJSONArray;
        if Assigned(IsNewArray) then
        begin
          SetLength(IsNew, IsNewArray.Count);
          for i := 0 to IsNewArray.Count - 1 do
            IsNew[i] := (IsNewArray.Items[i] as TJSONBool).AsBoolean;
        end;
        
        // Parse optional scrolling text
        ScrollingText := '';
        if DataObj.GetValue('scrolling_text') <> nil then
          ScrollingText := DataObj.GetValue('scrolling_text').Value;
        
        // Update display
        UpdateDisplay(QueueNumbers, IsNew);
        
        // Update scrolling text if provided
        if ScrollingText <> '' then
          ManageScrollingText(ScrollingText);
        
        // Send response back to caller
        SendDisplayResponse(QueueNumbers);
      end;
      
    finally
      JsonObj.Free;
    end;
    
  except
    on E: Exception do
    begin
      // Log JSON parsing error - in production this should use proper logging
      // For now, we'll silently handle the error to prevent crashes
    end;
  end;
end;

procedure TDisplayController.UpdateDisplay(const QueueNumbers: TArray<string>; const IsNew: TArray<Boolean>);
var
  i: Integer;
begin
  // Clear current queues
  FCurrentQueues.Clear;
  FBlinkingQueues.Clear;
  
  // Add new queues and track which ones should blink
  for i := 0 to High(QueueNumbers) do
  begin
    FCurrentQueues.Add(QueueNumbers[i]);
    if (i <= High(IsNew)) and IsNew[i] then
      FBlinkingQueues.Add(QueueNumbers[i]);
  end;
  
  // Update the display form
  if Assigned(FDisplayForm) then
    TfrmDisplay(FDisplayForm).UpdateDisplay(QueueNumbers, IsNew);
end;

procedure TDisplayController.BlinkNewNumbers(const QueueNumbers: TArray<string>);
var
  i: Integer;
begin
  // Add numbers to blinking list
  for i := 0 to High(QueueNumbers) do
  begin
    if FBlinkingQueues.IndexOf(QueueNumbers[i]) < 0 then
      FBlinkingQueues.Add(QueueNumbers[i]);
  end;
end;

procedure TDisplayController.ManageScrollingText(const Text: string);
begin
  // Update scrolling text
  if Assigned(FDisplayForm) and Assigned(TfrmDisplay(FDisplayForm).lblScrollingText) then
    TfrmDisplay(FDisplayForm).lblScrollingText.Caption := Text;
end;

procedure TDisplayController.SendDisplayResponse(const QueueNumbers: TArray<string>);
var
  JsonObj: TJSONObject;
  DataObj: TJSONObject;
  QueueArray: TJSONArray;
  i: Integer;
  ResponseJson: string;
  WebSocketManager: TWebSocketClientManager;
begin
  // Create response JSON
  JsonObj := TJSONObject.Create;
  try
    JsonObj.AddPair('type', 'display_status');
    JsonObj.AddPair('timestamp', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss"Z"', Now));
    
    DataObj := TJSONObject.Create;
    DataObj.AddPair('status', 'received');
    
    QueueArray := TJSONArray.Create;
    for i := 0 to High(QueueNumbers) do
      QueueArray.AddElement(TJSONString.Create(QueueNumbers[i]));
    DataObj.AddPair('displayed_numbers', QueueArray);
    
    DataObj.AddPair('terminal_id', 'TERMINAL_01');
    JsonObj.AddPair('data', DataObj);
    
    ResponseJson := JsonObj.ToString;
    
    // Send response via WebSocket
    if Assigned(FDisplayForm) then
    begin
      WebSocketManager := TfrmDisplay(FDisplayForm).WebSocketClientManager;
      if Assigned(WebSocketManager) and WebSocketManager.IsConnected then
        WebSocketManager.SendResponse(ResponseJson);
    end;
    
  finally
    JsonObj.Free;
  end;
end;

end.