# Delphi Queue System

ระบบคิวแบบแยกโปรเจค (Queue System) ที่พัฒนาด้วย Delphi 10.3 และ MySQL v.8

## โครงสร้างโปรเจค

```
├── CallerApp/          # แอปพลิเคชันสำหรับเรียกคิว
│   ├── CallerApp.dpr   # Main project file
│   ├── MainForm.pas    # หน้าจอหลัก
│   ├── DatabaseManager.pas    # จัดการฐานข้อมูล
│   ├── WebSocketManager.pas   # จัดการ WebSocket Server
│   └── QueueController.pas    # ตรรกะการจัดการคิว
├── TerminalApp/        # แอปพลิเคชันสำหรับแสดงผล
│   ├── TerminalApp.dpr # Main project file
│   ├── DisplayForm.pas # หน้าจอแสดงผล
│   ├── WebSocketClientManager.pas # จัดการ WebSocket Client
│   └── DisplayController.pas      # ตรรกะการแสดงผล
├── database/           # SQL Scripts
│   └── create_tables.sql # สคริปต์สร้างตาราง
└── config.ini          # ไฟล์การตั้งค่า
```

## การติดตั้งและตั้งค่า

### 1. ฐานข้อมูล MySQL

1. ติดตั้ง MySQL v.8
2. รันสคริปต์ `database/create_tables.sql` เพื่อสร้างฐานข้อมูลและตาราง
3. แก้ไขการตั้งค่าในไฟล์ `config.ini` ให้ตรงกับการตั้งค่าฐานข้อมูลของคุณ

### 2. Dependencies

โปรเจคต้องการ components ต่อไปนี้:
- **UniDAC**: สำหรับการเชื่อมต่อฐานข้อมูล MySQL
- **sgcWebSockets**: สำหรับการสื่อสาร WebSocket

### 3. การคอมไพล์

1. เปิด Delphi 10.3
2. เปิดไฟล์ `CallerApp/CallerApp.dproj` และ `TerminalApp/TerminalApp.dproj`
3. คอมไพล์ทั้งสองโปรเจค

## การใช้งาน

### Caller Application
1. รันแอปพลิเคชัน CallerApp
2. ระบบจะแสดงตาราง 3x3 ของหมายเลขคิว (0001-0009)
3. สีเขียว = มีข้อมูลในฐานข้อมูล, สีแดง = ไม่มีข้อมูล
4. คลิกหมายเลขเพื่อเลือก (สีม่วง)
5. กดปุ่ม "Send Selected" เพื่อส่งไปยัง Terminal

### Terminal Application
1. รันแอปพลิเคชัน TerminalApp
2. ระบบจะแสดงหน้าจอแสดงผลแบบเต็มจอ
3. หมายเลขใหม่จะกระพริบ, หมายเลขเก่าจะแสดงคงที่

## การตั้งค่า (config.ini)

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

## โครงสร้างฐานข้อมูล

### ตาราง queue_status
เก็บสถานะปัจจุบันของแต่ละหมายเลขคิว

### ตาราง queue_history
เก็บประวัติการเรียกคิว

### ตาราง connection_settings
เก็บการตั้งค่าระบบ

## การพัฒนาต่อ

โปรเจคนี้เป็นโครงสร้างพื้นฐาน สามารถพัฒนาต่อได้ตาม tasks ใน `.kiro/specs/delphi-queue-system/tasks.md`