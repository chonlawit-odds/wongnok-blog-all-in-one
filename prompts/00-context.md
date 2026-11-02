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

## รูปแบบการตอบ

- บอกชื่อไฟล์ทุกไฟล์ที่แก้หรือสร้าง
- ถ้าต้องมี migration ให้เขียนมาด้วย
- อย่าเพิ่ง refactor อย่างอื่นที่ไม่ได้ขอ
