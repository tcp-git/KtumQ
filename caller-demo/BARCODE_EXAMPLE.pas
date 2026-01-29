// ตัวอย่างการทำให้ KeyPress และ Button Click ทำงานร่วมกัน
// ไฟล์นี้เป็นตัวอย่างเท่านั้น ไม่ใช่ไฟล์จริง

unit BarcodeExample;

interface

type
  TMainForm = class(TForm)
    edtBarcodeInput: TEdit;
    btnBarcodeInput: TButton;
    
    // Event declarations
    procedure edtBarcodeInputKeyPress(Sender: TObject; var Key: Char);
    procedure btnBarcodeInputClick(Sender: TObject);
    
  private
    // ฟังก์ชันกลางสำหรับประมวลผลบาร์โค้ด
    procedure ProcessBarcodeFromInput;
    procedure ProcessBarcodeInput(const Barcode: string);
  end;

implementation

// ฟังก์ชันกลางที่จะถูกเรียกจากทั้ง KeyPress และ Button Click
procedure TMainForm.ProcessBarcodeFromInput;
var
  Barcode: string;
begin
  Barcode := Trim(edtBarcodeInput.Text);
  
  if Barcode <> '' then
  begin
    ProcessBarcodeInput(Barcode);
    edtBarcodeInput.Clear; // ล้างช่องกรอกหลังประมวลผล
  end;
end;

// Event: เมื่อกดปุ่ม Enter ใน TextBox
procedure TMainForm.edtBarcodeInputKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0; // ป้องกันเสียง beep
    ProcessBarcodeFromInput; // เรียกใช้ฟังก์ชันกลาง
  end;
end;

// Event: เมื่อคลิกปุ่ม
procedure TMainForm.btnBarcodeInputClick(Sender: TObject);
begin
  ProcessBarcodeFromInput; // เรียกใช้ฟังก์ชันกลางเดียวกัน
end;

// ฟังก์ชันประมวลผลบาร์โค้ดจริง (ตามที่มีอยู่ในโค้ดของคุณ)
procedure TMainForm.ProcessBarcodeInput(const Barcode: string);
var
  Query: TUniQuery;
  QueueNumber, RoomName: string;
begin
  // ตรวจสอบว่าเชื่อมต่อฐานข้อมูลหรือไม่
  if not FDatabaseConnected then
  begin
    ShowMessageAtForm('ไม่สามารถเรียกคิวได้: ไม่ได้เชื่อมต่อฐานข้อมูล');
    Exit;
  end;
  
  // ตรวจสอบว่าเลือกช่องบริการแล้วหรือไม่
  if FSelectedCounter = 0 then
  begin
    ShowMessageAtForm('กรุณาเลือกช่องบริการก่อนสแกนบาร์โค้ด');
    Exit;
  end;
  
  // ค้นหาคิวจากบาร์โค้ดและดึงข้อมูล
  Query := TUniQuery.Create(nil);
  try
    Query.Connection := UniConnection1;
    Query.SQL.Text := 
      'SELECT qdisplay, room FROM queue_data ' +
      'WHERE barcodes = :barcode AND fstatus = ''2'' AND timestamp >= CURDATE() AND timestamp < CURDATE() + INTERVAL 1 DAY';
    Query.ParamByName('barcode').AsString := Barcode;
    Query.Open;
    
    if Query.IsEmpty then
    begin
      ShowMessageAtForm('ไม่พบหมายเลขคิวในระบบ');
      Exit;
    end;
    
    QueueNumber := Query.FieldByName('qdisplay').AsString;
    case Query.FieldByName('room').AsInteger of
      1: RoomName := 'ยาปริมาณมาก';
      2: RoomName := 'ยาปริมาณน้อย';
      3: RoomName := 'กลับบ้านไม่มียา';
      4: RoomName := 'ยาขอก่อน';
    else
      RoomName := 'ไม่ทราบ';
    end;
  finally
    Query.Free;
  end;
  
  // อัพเดทสถานะคิว
  try
    UpdateQueueStatus(Barcode);
    SendQueueCalledMessage(QueueNumber, RoomName);
    RefreshQueueStatus;
    ShowMessageAtForm('เรียกคิว ' + QueueNumber + ' สำเร็จ');
  except
    on E: Exception do
      ShowMessageAtForm('เกิดข้อผิดพลาดในการเรียกคิว: ' + E.Message);
  end;
end;

end.

// ============================================================
// สรุปวิธีการ:
// ============================================================
// 1. สร้างฟังก์ชัน ProcessBarcodeFromInput() เป็นฟังก์ชันกลาง
//    - อ่านค่าจาก edtBarcodeInput
//    - เรียก ProcessBarcodeInput(Barcode) เพื่อประมวลผล
//    - ล้างช่อง edtBarcodeInput
//
// 2. edtBarcodeInputKeyPress เรียกใช้ ProcessBarcodeFromInput() เมื่อกด Enter
//
// 3. btnBarcodeInputClick เรียกใช้ ProcessBarcodeFromInput() เมื่อคลิกปุ่ม
//
// ============================================================
// ข้อดี:
// ============================================================
// ✅ Code ไม่ซ้ำซ้อน (DRY - Don't Repeat Yourself)
// ✅ แก้ไขที่เดียว ใช้งานได้ทั้งสองที่
// ✅ ง่ายต่อการบำรุงรักษา
// ✅ ทั้ง KeyPress และ Button Click ทำงานเหมือนกัน
