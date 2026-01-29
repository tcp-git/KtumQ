# แผนการพัฒนา

- [x] 1. ตั้งค่าโครงสร้างโปรเจคและฐานข้อมูล





  - สร้างโปรเจค Caller และ Terminal แยกกัน
  - สร้างตาราง queue_status, queue_history, connection_settings ใน MySQL
  - ตั้งค่าไฟล์ config.ini
  - _Requirements: 6.1, 6.2_

- [ ]* 1.1 เขียน property test สำหรับการโหลดการตั้งค่า INI
  - **Property 2: INI Configuration Loading**
  - **Validates: Requirements 1.5**

- [x] 2. พัฒนา Caller Application - ส่วนฐานข้อมูลและการเชื่อมต่อ





  - สร้าง TDatabaseManager ด้วย UniConnection
  - สร้าง TWebSocketManager ด้วย TsgcWebSocketServer
  - เขียนฟังก์ชันอ่านไฟล์ INI และเชื่อมต่อฐานข้อมูล
  - _Requirements: 1.5, 6.2_

- [ ]* 2.1 เขียน property test สำหรับการแสดงสีตามสถานะฐานข้อมูล
  - **Property 1: Database Status Color Mapping**
  - **Validates: Requirements 1.2, 1.3**

- [ ]* 2.2 เขียน property test สำหรับการจัดเก็บข้อมูล
  - **Property 13: Data Persistence**
  - **Validates: Requirements 6.4**

- [x] 3. พัฒนา Caller Application - UI และการนำทาง




  - สร้าง TMainForm ด้วยตาราง 3x3 (9 TPanel)
  - เพิ่มปุ่ม First, Next, Prev, Last
  - เขียน TQueueController สำหรับตรรกะการนำทาง
  - _Requirements: 1.1, 2.1, 2.2, 2.3, 2.4_

- [ ]* 3.1 เขียน property test สำหรับการนำทางตามลำดับ
  - **Property 3: Sequential Navigation Consistency**
  - **Validates: Requirements 2.2, 2.3**

- [x] 4. พัฒนา Caller Application - การเลือกและส่งคิว






  - เขียนฟังก์ชันการเลือกหมายเลข (เปลี่ยนสีเป็นม่วง)
  - เขียนฟังก์ชันการยกเลิกการเลือก (toggle)
  - เขียนฟังก์ชันส่งข้อมูล JSON ผ่าน WebSocket
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ]* 4.1 เขียน property test สำหรับการเลือกคิว
  - **Property 4: Queue Selection Toggle**
  - **Validates: Requirements 3.1, 3.2**

- [ ]* 4.2 เขียน property test สำหรับการเลือกหลายคิว
  - **Property 5: Multiple Queue Selection**
  - **Validates: Requirements 3.3**

- [ ]* 4.3 เขียน property test สำหรับรูปแบบ JSON
  - **Property 6: JSON Message Format**
  - **Validates: Requirements 3.4**

- [ ]* 4.4 เขียน property test สำหรับการจดจำสถานะการส่ง
  - **Property 7: Send Status Persistence**
  - **Validates: Requirements 3.5**

- [x] 5. พัฒนา Terminal Application - โครงสร้างพื้นฐาน





  - สร้าง TDisplayForm ด้วยตาราง 3x3 (9 TLabel ขนาดใหญ่)
  - สร้าง TWebSocketClientManager ด้วย TsgcWebSocketClient
  - เขียน TDisplayController สำหรับตรรกะการแสดงผล
  - _Requirements: 4.1, 6.3_

- [ ]* 5.1 เขียน property test สำหรับการอัปเดตการแสดงผล
  - **Property 8: Terminal Display Update**
  - **Validates: Requirements 4.2**

- [x] 6. พัฒนา Terminal Application - การแสดงผลและการกระพริบ





  - เขียนฟังก์ชันรับและประมวลผล JSON
  - เขียนฟังก์ชันการกระพริบสำหรับหมายเลขใหม่
  - เขียนฟังก์ชันการแสดงผลคงที่สำหรับหมายเลขเก่า
  - เพิ่มพื้นที่ข้อความวิ่ง
  - _Requirements: 4.2, 4.3, 4.4, 4.5_

- [ ]* 6.1 เขียน property test สำหรับการกระพริบหมายเลขใหม่
  - **Property 9: New Number Blinking**
  - **Validates: Requirements 4.3**

- [ ]* 6.2 เขียน property test สำหรับการแสดงหมายเลขเก่า
  - **Property 10: Old Number Steady Display**
  - **Validates: Requirements 4.4**

- [ ]* 6.3 เขียน property test สำหรับการแยกแยะหมายเลขใหม่-เก่า
  - **Property 12: New vs Old Number Processing**
  - **Validates: Requirements 5.4**

- [x] 7. เพิ่มฟีเจอร์ขั้นสูงและการจัดการข้อผิดพลาด





  - เพิ่มฟังก์ชัน auto-connect สำหรับ WebSocket
  - สร้างฟอร์มการตั้งค่าการเชื่อมต่อ
  - เขียนระบบจัดการข้อผิดพลาดและ error logging
  - _Requirements: 5.1, 5.2_

- [ ] 7.1 เขียน property test สำหรับการส่งคิวแบบยืดหยุ่น




  - **Property 11: Flexible Queue Transmission**
  - **Validates: Requirements 5.3**

- [x] 8. ทดสอบและปรับปรุงระบบ





  - ทดสอบการสื่อสารระหว่าง Caller และ Terminal
  - ตรวจสอบการทำงานของระบบ auto-reconnect
  - ปรับปรุงประสิทธิภาพและ UI/UX
  - _Requirements: 5.1, 5.3, 5.4_

- [x] 9. Checkpoint สุดท้าย - ตรวจสอบการทำงานทั้งระบบ





  - ตรวจสอบให้แน่ใจว่าทุก test ผ่าน ถามผู้ใช้หากมีคำถาม