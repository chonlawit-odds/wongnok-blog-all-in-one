## เป้าหมาย

หน้า /posts เร็วขึ้นอย่างมีนัยสำคัญ
โดยไม่ต้องเขียนโค้ดลบ cache เองเลยสักบรรทัด

## ข้อกำหนด

- fragment cache ต่อการ์ดโพสต์ 1 ใบ ด้วย <% cache post %>
- ซ้อนอีกชั้นด้วย cache ของทั้งรายการ (Russian doll)
- Comment belongs_to :post, touch: true
- ใช้ counter_cache สำหรับจำนวน comment (เพิ่มคอลัมน์ + backfill ค่าเดิม)
- ใช้ Solid Cache (ค่าเริ่มต้น) ไม่ต้องต่อ Redis
- เปิด config.action_controller.perform_caching ใน development เพื่อให้ทดสอบได้

## ห้าม

- เรียก Rails.cache.delete ที่ไหนก็ตาม
- ใส่ expires_in กับของที่มี updated_at
- cache ชิ้นที่มีข้อมูลเฉพาะผู้ใช้ข้างใน (ถ้ามี ให้ย้ายออกนอกกล่อง cache)
- backfill counter ด้วย loop ทีละแถว (ใช้ update_all)

## เกณฑ์ตรวจรับ

- [ ] refresh ครั้งที่ 2 เร็วกว่าครั้งแรกชัดเจน (ดู log)
- [ ] log ครั้งที่ 2 เห็น Read fragment hit
- [ ] แก้ title ใน console -> refresh -> เห็นของใหม่ โดยที่เราไม่ได้ลบ cache เลย
- [ ] เพิ่ม comment -> การ์ดใบนั้นอัปเดต ใบอื่นยัง hit
- [ ] grep หา Rails.cache.delete แล้วไม่เจอ
- [ ] ในกล่อง cache ไม่มี current_user อยู่ข้างใน
