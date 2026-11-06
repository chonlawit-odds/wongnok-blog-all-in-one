# บริบทของโปรเจค wongnok_blog

## Stack

- Ruby 4.0.5 / Rails 8.1.3 / PostgreSQL 18
- Propshaft + importmap  (ห้ามใช้ Sprockets, ห้ามแนะนำ npm หรือ node_modules)
- tailwindcss-rails (Tailwind v4) + daisyUI 5 ผ่าน @plugin ในไฟล์ CSS
  ห้ามสร้าง tailwind.config.js — Tailwind v4 ไม่อ่านไฟล์นั้น
- Solid Queue / Solid Cache / Solid Cable
- Active Storage -> MinIO (S3-compatible)
- Minitest (ไม่ใช่ RSpec)

## รูปแบบโค้ด

- ข้อความที่ผู้ใช้เห็นเป็นภาษาไทย ผ่าน i18n
- ใช้ params.expect ไม่ใช่ params.require(...).permit(...)
- ตั้งชื่อตาม convention ของ Rails เสมอ
- ห้ามมี `<script>` ใน view

## สีและ theme  (ต้องดูออกทั้ง light/dark)

- ห้ามสีตายตัว (bg-gray-100, text-white, border-red-400) และห้าม dark:
  ใช้สี daisyUI: base-100/200/300, base-content, primary, error ฯลฯ
- ใช้ component daisyUI ก่อน: btn, input, textarea, alert, card, badge
- ตั้งสีพื้นต้องตั้งสีตัวหนังสือคู่ เช่น bg-primary + text-primary-content
- ตัวหนังสือจาง: text-base-content/60
- theme ที่สร้างเอง ต้องมีทั้ง light และ dark
- เช็ก: `grep -rnE "(bg|text|border)-(gray|red|blue|green|white|black)" app/views` ต้องไม่เจอ

## การสลับธีม  (light/dark)

- theme ของ daisyUI: `light` (default) / `dark` (ตามเครื่อง)
- ตั้ง `data-theme` บน `<html>` เท่านั้น ห้ามใส่บน div ย่อยหรือเขียนตายตัวใน layout
- logic: `controllers/theme_controller.js` จำค่าใน localStorage key `theme`
- ปุ่ม: `shared/_navbar.html.erb` ห้ามใช้ class `theme-controller` ของ daisyUI
- refresh แล้วสีกะพริบ: แก้ด้วย cookie + server ใส่ data-theme ไม่ใช่ `<script>` ใน view

## กฎที่ห้ามลืม  (จากวันก่อน)

1. validates uniqueness ต้องมี unique index ที่ DB คู่เสมอ
2. validates presence ต้องมี NOT NULL ที่ DB คู่เสมอ
3. คอลัมน์ที่ใช้ค้นหาหรือเป็น foreign key ต้องมี index
4. ระบุ dependent: ของทุก association เสมอ และเลือกจากกฎธุรกิจ
5. ตรงที่วน each ต้องมี includes
6. index action ต้องมี limit หรือ pagination
7. migration ต้องไม่ล็อกตารางที่มีข้อมูลเยอะ — ใช้ expand-contract
8. strong parameters ไม่ใช่ authorization — แยกให้ออก
9. partial รับค่าผ่าน local เท่านั้น ห้ามอ้าง instance variable ข้างใน
10. ห้ามใช้ raw หรือ html_safe กับข้อมูลที่มาจากผู้ใช้ ตัดข้อความด้วย truncate ไม่ใช่ substring (substring ตัดสระไทยขาด)
11. ชื่อคลาส Tailwind ต้องเขียนเต็มเป็นข้อความ ห้ามต่อจากตัวแปร และใช้ semantic color ของ daisyUI (primary, base-100) ไม่ใช่ bg-blue-600
12. JS ทุกบรรทัดอยู่ใน Stimulus controller ห้ามมี `<script>` ใน view controller ที่สร้างของใน connect ต้องเก็บกวาดใน disconnect
13. turbo-frame id ใช้ dom_id() ทั้งสองฝั่ง ห้าม hardcode เป็น string
14. render ใหม่หลัง validation ไม่ผ่าน ต้องมี status: :unprocessable_content และใช้ after_commit ไม่ใช่ after_save เมื่อต้องยิงงานต่อ
15. association ที่เป็น attachment หรือ rich text ต้องมี with_attached_*/with_rich_text_* ใน controller
    Bullet เตือน AVOID eager loading `"rich_text_*"` = false positive ห้ามลบ ให้ add_safelist ใน development.rb
16. validate ไฟล์จากเนื้อไฟล์จริง ไม่เชื่อ content_type ที่ client ส่งมา และห้ามตั้ง bucket เป็น public — ใช้ signed URL เสมอ
17. job ต้อง idempotent สมมติเสมอว่าจะถูกรันซ้ำ (retry, เข้าคิวซ้ำ, สอง worker หยิบพร้อมกัน)
    - เปลี่ยนสถานะ: guard ด้วยสถานะใน with_lock ตัดสินจากค่าล่าสุดใน DB
    - side effect ที่ทำซ้ำไม่ได้ (อีเมล, สร้างแถว): unique constraint ที่ DB + จองด้วย insert_all ON CONFLICT ก่อนทำ
      ไม่ใช่ validates uniqueness หรือ exists? แล้วค่อยสร้าง
    - ห้ามนับด้วย increment ให้นับจากจำนวนแถว
18. ส่งเฉพาะ id เข้า job ห้ามส่งก้อนข้อมูล ไฟล์ หรือ URL ที่หมดอายุได้ — โหลดสดและสร้างลิงก์ตอน perform
    job ของ Rails ที่ส่ง record ผ่าน GlobalID (broadcasts_to, broadcast_*_later_to, purge_later) ถือว่าผ่าน ห้ามแก้

## รูปแบบการตอบ

- บอกชื่อไฟล์ทุกไฟล์ที่แก้หรือสร้าง
- ถ้าต้องมี migration ให้เขียนมาด้วย
- อย่าเพิ่ง refactor อย่างอื่นที่ไม่ได้ขอ
