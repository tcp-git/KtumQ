# Caller Application - ระบบเรียกคิว

## ภาพรวม
แอปพลิเคชัน Caller สำหรับเรียกคิวและจัดการช่องบริการในระบบจัดการคิวโรงพยาบาล

## ข้อกำหนดระบบ
- Delphi 10.3 Rio หรือสูงกว่า
- UniDAC components สำหรับ MySQL
- sgcWebSocket components
- MySQL Server 5.7 หรือสูงกว่า

## โครงสร้างโปรเจกต์

```
caller_new/
├── Caller.dpr              - Main project file
├── Caller.dproj            - Delphi project configuration
├── MainFormU.pas           - Main form unit
├── MainFormU.dfm           - Main form design
├── ConfigFormU.pas         - Configuration form unit
├── ConfigFormU.dfm         - Configuration form design
├── config.ini.template     - Configuration template
└── README.md               - This file
```

## Components ที่ใช้

### Database Components
- **TUniConnection**: เชื่อมต่อกับ MySQL database
- **TUniQuery**: ดำเนินการ SQL queries
- **TMySQLUniProvider**: MySQL provider สำหรับ UniDAC

### WebSocket Components
- **TsgcWebSocketClient**: เชื่อมต่อกับ WebSocket server เพื่อส่งข้อมูลแบบ real-time

### Timer Components
- **TTimer**: Auto-refresh ข้อมูลคิวทุก 2 วินาที

## การติดตั้ง

1. เปิดโปรเจกต์ `Caller.dproj` ใน Delphi 10.3
2. ตรวจสอบว่าติดตั้ง UniDAC และ sgcWebSocket components แล้ว
3. คัดลอก `config.ini.template` เป็น `config.ini` และแก้ไขค่าตามต้องการ
4. Compile และ Run โปรเจกต์

## การตั้งค่า

แก้ไขไฟล์ `config.ini`:

```ini
[Database]
Host=localhost
Port=3306
Username=root
Password=your_password
DatabaseName=queue_system

[WebSocket]
ServerURL=localhost
Port=8080
```

## Features (จะพัฒนาในงานถัดไป)

- [ ] เลือกช่องบริการ (1-9)
- [ ] สแกนบาร์โค้ดเพื่อเรียกคิว
- [ ] ทำเครื่องหมายคิวรอนาน
- [ ] เรียกคิวด้วยตนเองตามประเภท
- [ ] แสดงสถิติคิวแต่ละประเภท
- [ ] จัดการคิวแบบ offline

## สถานะการพัฒนา

✅ Task 11: สร้างโครงสร้างโปรเจกต์ Caller - เสร็จสมบูรณ์
- สร้าง folder caller_new
- สร้าง Delphi 10.3 project
- เพิ่ม UniDAC components สำหรับ MySQL
- เพิ่ม TsgcWebSocketClient component
- เพิ่ม TTimer สำหรับ auto-refresh

## Requirements Coverage

งานนี้ครอบคลุม Requirements:
- 6.1-6.5: การเรียกคิวจาก Caller
- 7.1-7.3: การจัดการช่องบริการ

## หมายเหตุ

- โปรเจกต์นี้แยกจาก `caller` เดิมเพื่อให้สามารถพัฒนาแบบ clean slate
- ใช้ UniDAC แทน ADO เพื่อประสิทธิภาพที่ดีกว่า
- WebSocket จะทำงานแบบ asynchronous และมี auto-reconnect
- Timer จะ refresh ข้อมูลทุก 2 วินาทีตามที่กำหนดใน Requirements 10.3
