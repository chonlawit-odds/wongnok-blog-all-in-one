## เป้าหมาย

ตั้งเวลาเผยแพร่โพสต์ล่วงหน้าได้
พอถึงเวลา ระบบเผยแพร่เองและแจ้งคนติดตาม

## ข้อกำหนด

- เพิ่ม status (draft/scheduled/published) + scheduled_at + published_at พร้อม index ที่ scheduled_at
- ใช้ Solid Queue · เพิ่ม worker: bin/jobs ใน Procfile.dev
- PublishPostJob ต้อง idempotent ด้วย guard สถานะ และต้องมี unique constraint ที่ DB กันสอง worker ชนกัน
- ใช้ท่า recurring job กวาดทุกนาที ไม่ใช่ wait_until (เพราะผู้ใช้แก้เวลาได้)
- retry_on พร้อม backoff แบบถ่างออก
- discard_on RecordNotFound
- ส่งเฉพาะ id เข้า job ห้ามส่งก้อนข้อมูล

## ห้าม

- ส่งอีเมลใน callback ของ model
- ใช้ after_save (ต้อง after_commit)
- job ที่บวกเลขสะสมแทนการคำนวณใหม่
- ส่ง signed URL หรือ token เข้า job
- สมมติว่า job รันครั้งเดียว

## เกณฑ์ตรวจรับ

- [ ] ตั้งเวลา 1 นาทีข้างหน้า แล้วรอดู มันเผยแพร่เอง
- [ ] รัน PublishPostJob.perform_now(post) ซ้ำ 3 ครั้ง -> สถานะไม่เปลี่ยน และไม่มีอีเมลเพิ่ม
- [ ] แก้เวลาที่ตั้งไว้ แล้วมันเผยแพร่ตามเวลาใหม่
- [ ] ปิด worker แล้วกด -> งานค้างในคิว ไม่หาย เปิด worker กลับมา -> งานถูกทำ
- [ ] เปิดตาราง solid_queue_* ดูด้วย SQL ได้
