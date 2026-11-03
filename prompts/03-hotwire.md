## เป้าหมาย

1) แก้หัวข้อโพสต์ได้ในหน้าเดิม ไม่ต้องเปลี่ยนหน้า
2) เพิ่ม Comment ได้ และเด้งขึ้นทุกแท็บที่เปิดอยู่
3) ช่องพิมพ์ comment มีตัวนับอักษร

## ข้อกำหนด

- สร้าง model Comment: body:text author_name:string post:references (ยังไม่มีระบบล็อกอิน)
- validation + NOT NULL + index ครบคู่
- inline edit ใช้ turbo-frame ใช้ dom_id(post) ตั้ง id ทั้งสองฝั่ง
- เพิ่ม comment ตอบด้วย create.turbo_stream.erb append รายการ + update ตัวนับ + ล้างฟอร์ม
- real-time ใช้ broadcasts_to :post พร้อม later: true
- ตัวนับอักษรเป็น Stimulus controller ต้องมี disconnect ที่เก็บกวาด listener

## ห้าม

- เขียน addEventListener นอก Stimulus
- ใส่ `<script>` ใน view
- hardcode id ของ turbo-frame เป็น string
- ใช้ after_save (ต้องเป็น after_commit)
- ลืม status: :unprocessable_content  ตอน render ใหม่

## เกณฑ์ตรวจรับ

- [ ] กดแก้ไขแล้ว URL ไม่เปลี่ยน และส่วนอื่นไม่ขยับ
- [ ] เปิด 2 แท็บ พิมพ์แท็บหนึ่ง อีกแท็บขึ้นเอง
- [ ] ตัวนับจำนวน comment อัปเดตพร้อมกัน
- [ ] ฟอร์มว่างเองหลัง submit
- [ ] Stimulus controller มี disconnect
- [ ] เปิด /posts/1/edit ตรง ๆ ยังได้หน้าเต็ม
- [ ] console ไม่มี error เรื่อง matching turbo-frame
