# วิธีทำให้ KeyPress และ Button Click ทำงานร่วมกัน

## ปัญหา
คุณมีโค้ดสองส่วนที่ต้องการให้ทำงานเหมือนกัน:
1. `edtBarcodeInputKeyPress` - เมื่อกด Enter ใน TextBox
2. `btnBarcodeInputClick` - เมื่อคลิกปุ่ม

แต่โค้ดที่คุณเขียนมีปัญหา เพราะ:
- `btnBarcodeInputClick` ไม่มี parameter `Key` ดังนั้นไม่สามารถใช้ `if Key = #13 then` ได้

## วิธีแก้ไขที่ถูกต้อง

### 1. สร้างฟังก์ชันกลาง (Shared Function)

```pascal
private
  procedure ProcessBarcodeFromInput;  // ฟังก์ชันกลาง
```

### 2. เขียนฟังก์ชันกลางที่ทำงานร่วมกัน

```pascal
procedure TMainForm.ProcessBarcodeFromInput;
var
  Barcode: string;
begin
  Barcode := Trim(edtBarcodeInput.Text);
  
  if Barcode <> '' then
  begin
    ProcessBarcodeInput(Barcode);
    edtBarcodeInput.Clear;
  end;
end;
```

### 3. ให้ KeyPress เรียกใช้ฟังก์ชันกลาง

```pascal
procedure TMainForm.edtBarcodeInputKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0; // ป้องกันเสียง beep
    ProcessBarcodeFromInput;  // ✅ เรียกฟังก์ชันกลาง
  end;
end;
```

### 4. ให้ Button Click เรียกใช้ฟังก์ชันกลางเดียวกัน

```pascal
procedure TMainForm.btnBarcodeInputClick(Sender: TObject);
begin
  ProcessBarcodeFromInput;  // ✅ เรียกฟังก์ชันกลางเดียวกัน
end;
```

## สรุป

### โครงสร้างที่ถูกต้อง:
```
edtBarcodeInputKeyPress (กด Enter)
         ↓
         ↓ เรียกใช้
         ↓
    ProcessBarcodeFromInput() ← ฟังก์ชันกลาง
         ↑
         ↑ เรียกใช้
         ↑
btnBarcodeInputClick (คลิกปุ่ม)
```

### ข้อดี:
✅ Code ไม่ซ้ำซ้อน (DRY Principle)
✅ แก้ไขที่เดียว ใช้งานได้ทั้งสองที่
✅ ง่ายต่อการบำรุงรักษา
✅ ลดโอกาสเกิดข้อผิดพลาด

## การเพิ่มลงในโครงการจริง

1. เพิ่ม declaration ใน `private` section:
```pascal
private
  procedure ProcessBarcodeFromInput;
```

2. เพิ่ม implementation:
```pascal
procedure TMainForm.ProcessBarcodeFromInput;
var
  Barcode: string;
begin
  Barcode := Trim(edtBarcodeInput.Text);
  
  if Barcode <> '' then
  begin
    ProcessBarcodeInput(Barcode);
    edtBarcodeInput.Clear;
  end;
end;
```

3. แก้ไข `edtBarcodeInputKeyPress` ให้เรียกใช้:
```pascal
procedure TMainForm.edtBarcodeInputKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    ProcessBarcodeFromInput;
  end;
end;
```

4. แก้ไข `btnBarcodeInputClick` ให้เรียกใช้:
```pascal
procedure TMainForm.btnBarcodeInputClick(Sender: TObject);
begin
  ProcessBarcodeFromInput;
end;
```

## หมายเหตุ
- ฟังก์ชัน `ProcessBarcodeInput(const Barcode: string)` ต้องมีอยู่แล้วในโค้ดของคุณ
- ถ้ายังไม่มี ให้สร้างตามตัวอย่างใน BARCODE_EXAMPLE.pas
