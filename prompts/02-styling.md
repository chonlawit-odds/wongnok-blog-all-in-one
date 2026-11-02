## เป้าหมาย

ทำให้หน้า index กับ show ดูเป็นเว็บจริง
มี navbar และสลับธีมสว่าง/มืดได้

## ข้อกำหนด

- ใช้ component ของ daisyUI (card, navbar, badge)
  ไม่เขียน CSS เอง ไม่สร้างไฟล์ .css ใหม่
- ใช้ semantic color (primary, base-100)
  ไม่ใช่ bg-blue-600
- navbar เป็น partial shared/_navbar.html.erb
- ปุ่มสลับธีม เปลี่ยน data-theme บน `<html>`
- จำธีมที่เลือกไว้ใน localStorage
- responsive ใช้ได้บนมือถือ

## ห้าม

- สร้าง tailwind.config.js (เราใช้ v4)
- ต่อ string เป็นชื่อคลาส Tailwind
- แนะนำให้ npm install หรือเพิ่ม package.json
- เขียน `<style>` ใน view

## เกณฑ์ตรวจรับ

- [ ] สลับธีมแล้วเปลี่ยนทั้งเว็บ ไม่ใช่แค่บางส่วน
- [ ] refresh แล้วธีมที่เลือกยังอยู่
- [ ] รัน assets:precompile แล้วสียังอยู่ครบ
- [ ] ไม่มีไฟล์ใหม่ในโปรเจคนอกจาก .erb
- [ ] ย่อหน้าต่างเหลือความกว้างมือถือแล้วยังอ่านได้
