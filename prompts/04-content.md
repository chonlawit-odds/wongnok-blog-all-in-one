## เป้าหมาย

เปลี่ยน description เป็น rich text แก้ไขได้
เพิ่มรูปปกให้โพสต์ เก็บใน MinIO และโชว์รูปย่อในหน้า index

## ข้อกำหนด

- ใช้ Action Text สำหรับเนื้อหา (has_rich_text :body)
- ย้ายข้อมูลเดิมจาก description มา body
  ใช้ท่า expand-contract ไม่ลบคอลัมน์เก่าในรอบนี้
- รูปปกใช้ Active Storage -> service minio
- เปิด direct_upload: true
- validate ชนิดไฟล์ (png/jpeg/webp) และขนาด <= 5MB
- index ใช้ variant resize_to_limit [400,300]
- controller ต้องมี with_attached_cover
  และ with_rich_text_body
- เพิ่มคอลัมน์ plain_text สำหรับค้นหาภายหลัง

## ห้าม

- raw หรือ html_safe กับ body ที่ไหนก็ตาม
- ตั้ง bucket เป็น public
- เชื่อ content_type ที่ client ส่งมาอย่างเดียว
- เขียน access key ลง storage.yml ตรง ๆ
- ลบคอลัมน์ description ในรอบนี้

## เกณฑ์ตรวจรับ

- [ ] พิมพ์ตัวหนา ใส่ลิงก์ ในเนื้อหาได้
- [ ] อัปรูปแล้วเปิด MinIO console เห็นไฟล์จริง
- [ ] ก๊อป URL รูปไปเปิด incognito -> ใช้ได้ แล้วรอหมดอายุ
- [ ] Network tab: ไฟล์ขึ้นตรงไป :9000 ไม่ผ่าน :3000
- [ ] log หน้า index ไม่เกิน 6 query
- [ ] อัปไฟล์ .txt ที่เปลี่ยนนามสกุลเป็น .png -> ต้องถูกปฏิเสธ
- [ ] ข้อมูลเดิม 30 โพสต์ยังอ่านได้ครบ
