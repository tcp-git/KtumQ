# สรุปการทำงาน Task 17.1 - Write Property Test for Next Queue Selection

## งานที่ทำ

สร้าง property-based tests สำหรับการเลือกคิวถัดไปและการอัพเดทสถานะคิวเมื่อเรียกด้วยตนเอง

## ไฟล์ที่สร้าง/แก้ไข

### 1. QueueSelectionTests.pas (ไฟล์ใหม่)
สร้าง test unit ใหม่ที่มี 2 property tests:

#### Property 19: Next Queue Selection
- **ตรวจสอบ**: Requirements 10.2, 11.1, 11.2, 11.3, 11.4
- **ทดสอบ**: การเลือกคิวถัดไปที่จะเรียกต้องเป็นคิวที่มี timestamp เก่าที่สุด โดยมีสถานะ fstatus="2" และ room ตรงกับประเภทบริการ
- **จำนวน iterations**: 100 ครั้ง
- **การทดสอบ**:
  - สร้างคิว 5 คิวสำหรับแต่ละ room โดยมี timestamp ต่างกัน
  - ตรวจสอบว่าฟังก์ชัน `GetNextQueueForRoom` เลือกคิวที่มี timestamp เก่าที่สุด
  - ตรวจสอบว่าคิวที่ถูกเรียกไปแล้ว (fstatus="1") จะไม่ถูกเลือก
  - ทดสอบ edge cases: ไม่มีคิวรอ, มีแต่คิวที่ถูกเรียกไปแล้ว

#### Property 20: Manual Call Queue Update
- **ตรวจสอบ**: Requirements 11.5
- **ทดสอบ**: เมื่อเรียกคิวด้วยตนเอง ระบบต้องอัพเดทสถานะเป็น "เรียกแล้ว", ตั้งค่าช่องบริการ, ตั้งค่า time_confirm และส่ง WebSocket message
- **จำนวน iterations**: 100 ครั้ง
- **การทดสอบ**:
  - สร้างคิวทดสอบสำหรับแต่ละ room (1-4)
  - ตั้งค่าช่องบริการ (1-9)
  - เรียกคิวและตรวจสอบว่าข้อมูลถูกอัพเดทถูกต้อง:
    - fstatus = "1" (เรียกแล้ว)
    - counters = หมายเลขช่องบริการที่เลือก
    - time_confirm = เวลาปัจจุบัน (ภายใน 5 วินาที)
  - ตรวจสอบว่ามี WebSocket message ถูกส่ง (หรือเก็บใน offline queue)
  - ทดสอบ edge case: เรียกคิวโดยไม่เลือกช่องบริการ

### 2. CallerTests.dpr (แก้ไข)
เพิ่ม `QueueSelectionTests` เข้าไปใน uses clause

## โครงสร้างการทดสอบ

```pascal
// Property 19: Next Queue Selection
procedure TestNextQueueSelection_MultipleIterations;
- สร้างคิว 5 คิวต่อ iteration โดยมี timestamp ต่างกัน
- ใช้ฟังก์ชัน GetNextQueueForRoom เพื่อหาคิวถัดไป
- ตรวจสอบว่าคิวที่เลือกมี timestamp เก่าที่สุด
- ทดสอบว่าคิวที่ถูกเรียกไปแล้วจะไม่ถูกเลือก

// Property 20: Manual Call Queue Update
procedure TestManualCallQueueUpdate_MultipleIterations;
- สร้างคิวทดสอบ 1 คิวต่อ iteration
- ตั้งค่าช่องบริการ
- เรียกคิวด้วย UpdateQueueStatus
- ตรวจสอบว่าข้อมูลในฐานข้อมูลถูกอัพเดทครบถ้วน
- ตรวจสอบว่ามี WebSocket message ถูกส่ง
```

## ฟังก์ชันที่ทดสอบ

1. **GetNextQueueForRoom(RoomID: Integer; out QueueNumber: string; out QueueBarcode: string): Boolean**
   - หาคิวถัดไปที่ยังไม่ถูกเรียกสำหรับประเภทบริการที่กำหนด
   - เรียงลำดับตาม timestamp (เก่าที่สุดก่อน)
   - คืนค่า True ถ้าพบคิว, False ถ้าไม่พบ

2. **UpdateQueueStatus(const Barcode: string)**
   - อัพเดทสถานะคิวเป็น "เรียกแล้ว" (fstatus="1")
   - ตั้งค่าช่องบริการ (counters)
   - ตั้งค่าเวลาเรียกคิว (time_confirm)
   - ส่ง WebSocket message

## วิธีการรัน Tests

### ผ่าน Delphi IDE (แนะนำ)
1. เปิด `caller_new/Tests/CallerTests.dproj` ใน Delphi IDE
2. ตรวจสอบว่า library paths ถูกตั้งค่าถูกต้อง:
   - UniDAC library path
   - sgcWebSocket library path
   - DUnitX library path
3. Build project (Project → Build CallerTests)
4. Run tests (Run → Run Without Debugging หรือ Ctrl+Shift+F9)

### ผ่าน Command Line
```batch
cd caller_new\Tests
build_and_run_tests.bat
```

หมายเหตุ: อาจต้องปรับ path ของ Delphi compiler ใน batch file

## ผลลัพธ์ที่คาดหวัง

เมื่อ tests ผ่านทั้งหมด จะแสดง:
```
[PASS] TestNextQueueSelection_MultipleIterations
[PASS] TestManualCallQueueUpdate_MultipleIterations
Tests Run: 2, Passed: 2, Failed: 0
```

## Edge Cases ที่ทดสอบ

### Property 19:
1. ไม่มีคิวรอเลย → GetNextQueueForRoom ต้องคืนค่า False
2. มีแต่คิวที่ถูกเรียกไปแล้ว → GetNextQueueForRoom ต้องคืนค่า False
3. หลังเรียกคิวแรก คิวถัดไปต้องเป็นคิวที่ 2

### Property 20:
1. เรียกคิวโดยไม่เลือกช่องบริการ → SelectedCounter ต้องเป็น 0
2. WebSocket ไม่เชื่อมต่อ → ข้อความต้องถูกเก็บใน offline queue

## การทำความสะอาดข้อมูล

- ใช้ prefix `TEST_SELECTION_` สำหรับบาร์โค้ดทดสอบ
- ล้างข้อมูลทดสอบก่อนและหลังการรัน tests
- ใช้ `DELETE FROM queue_data WHERE barcodes LIKE 'TEST_SELECTION_%'`

## ข้อควรระวัง

1. **Database Connection**: Tests จะถูก skip ถ้าไม่สามารถเชื่อมต่อฐานข้อมูลได้
2. **Timestamp Precision**: ใช้ tolerance 1 วินาทีสำหรับการเปรียบเทียบ timestamp
3. **WebSocket Status**: Tests ตรวจสอบ offline queue เมื่อ WebSocket ไม่เชื่อมต่อ
4. **Sleep Delays**: ใช้ Sleep(10) เพื่อให้แน่ใจว่า timestamp ต่างกัน

## สถานะ

✅ Property tests ถูกสร้างเรียบร้อยแล้ว
⏳ รอการรัน tests ผ่าน Delphi IDE เพื่อยืนยันว่าผ่านทั้งหมด

## ขั้นตอนถัดไป

1. เปิด Delphi IDE
2. Load project CallerTests.dproj
3. Build และ run tests
4. ตรวจสอบผลลัพธ์
5. แก้ไขถ้ามี tests ที่ fail
