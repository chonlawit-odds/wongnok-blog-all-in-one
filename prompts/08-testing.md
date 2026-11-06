## เป้าหมาย

test ชุดแรกที่จับบั๊กได้จริง ไม่ใช่แค่ทวนโค้ด

## ข้อกำหนด

- fixtures: users somchai malee boss posts และ comments ครบทุกสถานะ ตั้งชื่อตามสถานการณ์ เช่น post_scheduled_tomorrow
- model test: validation ของ scheduled_at และ policy ทั้งสองตัว ทั้งเคสเจ้าของ คนอื่น และ admin
- integration test: เจ้าของแก้ได้ · คนอื่นได้ 404 และต้อง assert ว่า DB ไม่เปลี่ยนด้วย ไม่ใช่แค่ status
- job test: perform_now 3 รอบ แล้ว assert_emails 1
- assert_enqueued_with ว่า controller สั่งเข้าคิวจริง ไม่ได้ทำงานเองใน request
- system test เฉพาะ comment สด กับ inline edit
- bin/check รวม rubocop brakeman zeitwerk:check test ใช้ set -e ให้หยุดที่ตัวแรกที่ fail
- ให้ CI รันทั้ง test และ test:system
- เขียน definition of done ลง CLAUDE.md ว่าต้องรัน bin/check เองก่อนบอกว่าเสร็จ และห้ามแก้ .rubocop.yml เพื่อให้ผ่าน

## ห้าม

- assert กับ private method · ห้ามใช้ send
- แก้โค้ดในแอปเพื่อให้ test ผ่าน ถ้า test แดงเพราะโค้ดผิด ให้บอกเรา อย่าแก้เอง
- แก้ fixtures แถวเดิม ให้เพิ่มแถวใหม่
- เขียน system test เกินสองตัว
- assert แค่ status code ใน test ของสิทธิ์
- ใช้ sleep ใน system test
- ใช้ RSpec หรือ FactoryBot

## เกณฑ์ตรวจรับ

- [ ] ลบ policy check ออก 1 บรรทัด -> ต้องมี test แดง
- [ ] แก้ publish! ให้ไม่เช็คเวลา -> ต้องมี test แดง
- [ ] bin/check ผ่านทั้งหมดในสภาพปกติ
- [ ] รัน suite 3 รอบติด -> ผลเหมือนกันทั้งสามรอบ
- [ ] test:system รันผ่านแยกต่างหากด้วย
- [ ] เปิด localhost:8025 หลัง job test -> อีเมลใบเดียว
