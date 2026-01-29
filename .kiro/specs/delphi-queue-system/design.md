# เอกสารการออกแบบ

## ภาพรวม

ระบบคิว Delphi ประกอบด้วย 2 แอปพลิเคชันหลักที่เชื่อมต่อกันผ่าน WebSocket:

1. **Caller Application** - แอปพลิเคชันสำหรับจัดการและเรียกคิว เชื่อมต่อฐานข้อมูล MySQL
2. **Terminal Application** - แอปพลิเคชันสำหรับแสดงผลหมายเลขคิว ไม่เชื่อมต่อฐานข้อมูลโดยตรง

ระบบใช้ WebSocket เป็นช่องทางสื่อสารหลักระหว่าง Caller และ Terminal เพื่อให้การแสดงผลเป็น real-time

## สถาปัตยกรรม

### สถาปัตยกรรมระดับสูง

```
┌─────────────────┐    WebSocket     ┌─────────────────┐
│  Caller App     │◄────────────────►│  Terminal App   │
│                 │     JSON Data    │                 │
│ ┌─────────────┐ │                  │ ┌─────────────┐ │
│ │ UI Layer    │ │                  │ │ UI Layer    │ │
│ └─────────────┘ │                  │ └─────────────┘ │
│ ┌─────────────┐ │                  │ ┌─────────────┐ │
│ │Business     │ │                  │ │Display      │ │
│ │Logic        │ │                  │ │Logic        │ │
│ └─────────────┘ │                  │ └─────────────┘ │
│ ┌─────────────┐ │                  │ ┌─────────────┐ │
│ │Data Access  │ │                  │ │WebSocket    │ │
│ │Layer        │ │                  │ │Client       │ │
│ └─────────────┘ │                  │ └─────────────┘ │
└─────────────────┘                  └─────────────────┘
         │
         ▼
┌─────────────────┐
│   MySQL v.8     │
│   Database      │
└─────────────────┘
```

### แพทเทิร์นสถาปัตยกรรม

- **Model-View-Controller (MVC)** สำหรับ Caller Application
- **Observer Pattern** สำหรับการอัปเดต UI เมื่อมีการเปลี่ยนแปลงข้อมูล
- **Repository Pattern** สำหรับการเข้าถึงข้อมูล
- **Singleton Pattern** สำหรับการจัดการการเชื่อมต่อ WebSocket

## คอมโพเนนต์และอินเทอร์เฟซ

### Caller Application Components

#### 1. Main Form (TMainForm)
- **หน้าที่**: UI หลักสำหรับแสดงตาราง 3x3 และปุ่มควบคุม
- **คอมโพเนนต์**:
  - 9 TPanel สำหรับแสดงหมายเลขคิว (0001-0009)
  - 4 TButton สำหรับ First, Next, Prev, Last
  - TButton สำหรับส่งหมายเลขที่เลือก
  - TButton สำหรับตั้งค่าการเชื่อมต่อ

#### 2. Database Manager (TDatabaseManager)
- **หน้าที่**: จัดการการเชื่อมต่อฐานข้อมูลและการอ่านไฟล์ INI
- **คอมโพเนนต์**:
  - TUniConnection สำหรับเชื่อมต่อ MySQL
  - TUniQuery สำหรับ query ข้อมูล
  - TIniFile สำหรับอ่านการตั้งค่า

#### 3. WebSocket Manager (TWebSocketManager)
- **หน้าที่**: จัดการการเชื่อมต่อ WebSocket และส่งข้อมูล
- **คอมโพเนนต์**:
  - TsgcWebSocketServer สำหรับรับการเชื่อมต่อจาก Terminal

#### 4. Queue Controller (TQueueController)
- **หน้าที่**: ตรรกะทางธุรกิจสำหรับจัดการคิว
- **ฟังก์ชัน**:
  - CheckQueueStatus(): ตรวจสอบสถานะคิวจากฐานข้อมูล
  - SelectQueue(): เลือก/ยกเลิกการเลือกหมายเลขคิว
  - SendSelectedQueues(): ส่งหมายเลขที่เลือกไปยัง Terminal

### Terminal Application Components

#### 1. Display Form (TDisplayForm)
- **หน้าที่**: แสดงผลหมายเลขคิวแบบ 3x3
- **คอมโพเนนต์**:
  - 9 TLabel สำหรับแสดงหมายเลขขนาดใหญ่
  - TLabel สำหรับหัวข้อ
  - TPanel สำหรับข้อความวิ่ง
  - TTimer สำหรับการกระพริบ

#### 2. WebSocket Client Manager (TWebSocketClientManager)
- **หน้าที่**: รับข้อมูลจาก Caller ผ่าน WebSocket
- **คอมโพเนนต์**:
  - TsgcWebSocketClient สำหรับเชื่อมต่อกับ Caller

#### 3. Display Controller (TDisplayController)
- **หน้าที่**: ตรรกะการแสดงผลและการกระพริบ
- **ฟังก์ชัน**:
  - UpdateDisplay(): อัปเดตการแสดงผลตามข้อมูลที่ได้รับ
  - BlinkNewNumbers(): ทำให้หมายเลขใหม่กระพริบ
  - ManageScrollingText(): จัดการข้อความวิ่ง

## โมเดลข้อมูล

### ฐานข้อมูล MySQL

#### ตาราง queue_status
```sql
CREATE TABLE queue_status (
    id INT AUTO_INCREMENT PRIMARY KEY,
    queue_number VARCHAR(4) NOT NULL UNIQUE,
    has_data BOOLEAN DEFAULT FALSE,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_queue_number (queue_number)
);
```

#### ตาราง queue_history
```sql
CREATE TABLE queue_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    queue_numbers JSON NOT NULL,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sent_by VARCHAR(50) DEFAULT 'CALLER',
    status ENUM('SENT', 'DISPLAYED', 'COMPLETED') DEFAULT 'SENT'
);
```

#### ตาราง connection_settings
```sql
CREATE TABLE connection_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    setting_name VARCHAR(50) NOT NULL UNIQUE,
    setting_value TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### JSON Message Format

#### ข้อความส่งจาก Caller ไป Terminal
```json
{
    "type": "queue_call",
    "timestamp": "2024-01-29T10:30:00Z",
    "data": {
        "queue_numbers": ["0001", "0003", "0005", "0007"],
        "is_new": [true, false, true, false],
        "caller_id": "CALLER_01"
    }
}
```

#### ข้อความตอบกลับจาก Terminal
```json
{
    "type": "display_status",
    "timestamp": "2024-01-29T10:30:01Z",
    "data": {
        "status": "received",
        "displayed_numbers": ["0001", "0003", "0005", "0007"],
        "terminal_id": "TERMINAL_01"
    }
}
```

### การตั้งค่าไฟล์ INI

#### config.ini
```ini
[DATABASE]
Server=localhost
Port=3307
Database=queue_system
Username=root
Password=saas
ConnectionTimeout=30

[WEBSOCKET]
ServerPort=8080
ClientHost=localhost
ClientPort=8080
AutoReconnect=true
ReconnectInterval=5000

[DISPLAY]
BlinkInterval=500
BlinkDuration=3000
FontSize=48
GridSpacing=10
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Database Status Color Mapping
*สำหรับ* หมายเลขคิวใดๆ เมื่อสอบถามฐานข้อมูล สีที่แสดงควรตรงกับสถานะข้อมูล (เขียวถ้ามีข้อมูล แดงถ้าไม่มี)
**Validates: Requirements 1.2, 1.3**

### Property 2: INI Configuration Loading
*สำหรับ* ไฟล์ INI ใดๆ ที่มีการตั้งค่าที่ถูกต้อง ระบบควรอ่านและใช้ค่าการตั้งค่าได้อย่างถูกต้อง
**Validates: Requirements 1.5**

### Property 3: Sequential Navigation Consistency
*สำหรับ* ตำแหน่งปัจจุบันใดๆ การกดปุ่ม next ควรนำไปยังหมายเลขถัดไป และการกดปุ่ม previous ควรนำไปยังหมายเลขก่อนหน้า
**Validates: Requirements 2.2, 2.3**

### Property 4: Queue Selection Toggle
*สำหรับ* หมายเลขคิวใดๆ การคลิกครั้งแรกควรเปลี่ยนเป็นสีม่วง และการคลิกครั้งที่สองควรคืนสีเดิม
**Validates: Requirements 3.1, 3.2**

### Property 5: Multiple Queue Selection
*สำหรับ* ชุดหมายเลขคิวใดๆ ระบบควรอนุญาตให้เลือกหลายหมายเลขแบบไม่ต่อเนื่อง
**Validates: Requirements 3.3**

### Property 6: JSON Message Format
*สำหรับ* หมายเลขคิวที่เลือกใดๆ ข้อมูลที่ส่งผ่าน WebSocket ควรเป็น JSON ที่ถูกต้องและมีโครงสร้างตามที่กำหนด
**Validates: Requirements 3.4**

### Property 7: Send Status Persistence
*สำหรับ* หมายเลขคิวใดๆ ที่ถูกส่ง ระบบควรจดจำสถานะการส่งและสามารถเรียกดูได้
**Validates: Requirements 3.5**

### Property 8: Terminal Display Update
*สำหรับ* ข้อมูล JSON ใดๆ ที่ได้รับผ่าน WebSocket Terminal ควรอัปเดตการแสดงผลตามข้อมูลที่ได้รับ
**Validates: Requirements 4.2**

### Property 9: New Number Blinking
*สำหรับ* หมายเลขใดๆ ที่มี is_new=true ระบบควรทำให้หมายเลขนั้นกระพริบ
**Validates: Requirements 4.3**

### Property 10: Old Number Steady Display
*สำหรับ* หมายเลขใดๆ ที่มี is_new=false ระบบควรแสดงในสถานะคงที่โดยไม่กระพริบ
**Validates: Requirements 4.4**

### Property 11: Flexible Queue Transmission
*สำหรับ* จำนวนหมายเลขคิวใดๆ (1 หรือหลายตัว) ระบบควรส่งข้อมูลได้อย่างถูกต้อง
**Validates: Requirements 5.3**

### Property 12: New vs Old Number Processing
*สำหรับ* ข้อมูลใดๆ ที่มีทั้งหมายเลขใหม่และเก่า Terminal ควรแยกแยะและแสดงผลแตกต่างกัน
**Validates: Requirements 5.4**

### Property 13: Data Persistence
*สำหรับ* สถานะคิวและประวัติการส่งใดๆ ข้อมูลควรถูกบันทึกลงฐานข้อมูลอย่างถูกต้อง
**Validates: Requirements 6.4**

## การจัดการข้อผิดพลาด

### Caller Application Error Handling

1. **Database Connection Errors**
   - แสดงข้อความแจ้งเตือนเมื่อไม่สามารถเชื่อมต่อฐานข้อมูลได้
   - ลองเชื่อมต่อใหม่อัตโนมัติทุก 30 วินาที
   - แสดงสถานะการเชื่อมต่อบน status bar

2. **WebSocket Connection Errors**
   - แสดงสถานะการเชื่อมต่อ WebSocket
   - ลองเชื่อมต่อใหม่อัตโนมัติเมื่อการเชื่อมต่อขาด
   - บันทึก error log สำหรับการ debug

3. **INI File Errors**
   - สร้างไฟล์ INI ใหม่ด้วยค่า default หากไฟล์หาย
   - แสดงข้อความแจ้งเตือนเมื่อไฟล์ INI มีรูปแบบผิด
   - ใช้ค่า default เมื่ออ่านค่าจากไฟล์ไม่ได้

### Terminal Application Error Handling

1. **WebSocket Connection Errors**
   - แสดงสถานะการเชื่อมต่อบนหน้าจอ
   - ลองเชื่อมต่อใหม่อัตโนมัติ
   - แสดงข้อความ "กำลังเชื่อมต่อ..." เมื่อขาดการเชื่อมต่อ

2. **JSON Parsing Errors**
   - บันทึก error log เมื่อได้รับข้อมูล JSON ที่ผิดรูปแบบ
   - ข้ามข้อมูลที่ผิดรูปแบบและรอข้อมูลถัดไป
   - แสดงข้อความแจ้งเตือนใน debug mode

3. **Display Errors**
   - จัดการกรณีที่ได้รับหมายเลขคิวที่ไม่ถูกต้อง
   - แสดงข้อความ error แทนหมายเลขที่ผิด
   - รีเซ็ตการแสดงผลเมื่อเกิดข้อผิดพลาดร้ายแรง

## กลยุทธ์การทดสอบ

### Unit Testing
ระบบจะใช้ DUnit framework สำหรับการทดสอบ unit tests:

- **Database Operations**: ทดสอบการเชื่อมต่อ query และการจัดการข้อมูล
- **WebSocket Communication**: ทดสอบการส่งและรับข้อมูล JSON
- **UI Components**: ทดสอบการทำงานของปุ่มและการแสดงผล
- **Configuration Management**: ทดสอบการอ่านและเขียนไฟล์ INI

### Property-Based Testing
ระบบจะใช้ QuickCheck for Delphi สำหรับการทดสอบ property-based tests:

- แต่ละ property-based test จะรันอย่างน้อย 100 iterations
- แต่ละ property-based test จะมี comment ที่อ้างอิงถึง correctness property ในเอกสารการออกแบบ
- รูปแบบ comment: `**Feature: delphi-queue-system, Property {number}: {property_text}**`
- แต่ละ correctness property จะถูกใช้งานโดย property-based test เพียงตัวเดียว

### Integration Testing
- ทดสอบการสื่อสารระหว่าง Caller และ Terminal ผ่าน WebSocket
- ทดสอบการทำงานร่วมกันของฐานข้อมูลและ UI
- ทดสอบ end-to-end workflow ตั้งแต่การเลือกคิวจนถึงการแสดงผล

### การทดสอบแบบ Dual Approach
ระบบจะใช้ทั้ง unit tests และ property-based tests เพื่อให้ได้การทดสอบที่ครอบคลุม:
- Unit tests จะตรวจสอบตัวอย่างเฉพาะ edge cases และเงื่อนไขข้อผิดพลาด
- Property tests จะตรวจสอบคุณสมบัติสากลที่ควรเป็นจริงในทุกการป้อนข้อมูล
- ทั้งสองประเภทจะให้การครอบคลุมที่สมบูรณ์: unit tests จับข้อบกพร่องที่เป็นรูปธรรม property tests ตรวจสอบความถูกต้องโดยทั่วไป