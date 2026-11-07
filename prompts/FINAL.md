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
17. job ต้อง idempotent (retry, เข้าคิวซ้ำ, สอง worker พร้อมกัน): เปลี่ยนสถานะให้ตัดสินจากค่าล่าสุดใน with_lock
    side effect ที่ทำซ้ำไม่ได้ จองด้วย unique index + insert_all ON CONFLICT ก่อนทำ (ไม่ใช่ exists?/validates uniqueness) และนับจากจำนวนแถว ไม่ใช้ increment
18. ส่งแค่ id เข้า job แล้วโหลดสดตอน perform ห้ามส่งก้อนข้อมูล ไฟล์ หรือ URL ที่หมดอายุได้ (GlobalID ที่ Rails ส่งเอง เช่น broadcast_*_later_to, purge_later ถือว่าผ่าน)
19. ห้ามลบ cache เอง (Rails.cache.delete, expire_fragment) และห้ามใช้ expires_in แทน — ข้อมูลในกล่องเปลี่ยน cache key ต้องเปลี่ยนตาม
    ลูกในกล่องแม่ใช้ belongs_to touch: true, ข้อมูลแม่ในกล่องลูกให้แม่ touch_all ลูกตอนเปลี่ยน, เขียนด้วย update_all/insert_all ต้อง touch เอง
20. ในกล่อง cache ห้ามมีของที่ต่างกันต่อผู้ใช้หรือต่อ request (current_user, form/button_to ที่มี CSRF token, flash, เวลาแบบ "x นาทีที่แล้ว") ให้ย้ายออกนอกกล่อง

## รูปแบบการตอบ

- บอกชื่อไฟล์ทุกไฟล์ที่แก้หรือสร้าง
- ถ้าต้องมี migration ให้เขียนมาด้วย
- อย่าเพิ่ง refactor อย่างอื่นที่ไม่ได้ขอ
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
17. job ต้อง idempotent (retry, เข้าคิวซ้ำ, สอง worker พร้อมกัน): เปลี่ยนสถานะให้ตัดสินจากค่าล่าสุดใน with_lock
    side effect ที่ทำซ้ำไม่ได้ จองด้วย unique index + insert_all ON CONFLICT ก่อนทำ (ไม่ใช่ exists?/validates uniqueness) และนับจากจำนวนแถว ไม่ใช้ increment
18. ส่งแค่ id เข้า job แล้วโหลดสดตอน perform ห้ามส่งก้อนข้อมูล ไฟล์ หรือ URL ที่หมดอายุได้ (GlobalID ที่ Rails ส่งเอง เช่น broadcast_*_later_to, purge_later ถือว่าผ่าน)
19. ห้ามลบ cache เอง (Rails.cache.delete, expire_fragment) และห้ามใช้ expires_in แทน — ข้อมูลในกล่องเปลี่ยน cache key ต้องเปลี่ยนตาม
    ลูกในกล่องแม่ใช้ belongs_to touch: true, ข้อมูลแม่ในกล่องลูกให้แม่ touch_all ลูกตอนเปลี่ยน, เขียนด้วย update_all/insert_all ต้อง touch เอง
20. ในกล่อง cache ห้ามมีของที่ต่างกันต่อผู้ใช้หรือต่อ request (current_user, form/button_to ที่มี CSRF token, flash, เวลาแบบ "x นาทีที่แล้ว") ให้ย้ายออกนอกกล่อง

## รูปแบบการตอบ

- บอกชื่อไฟล์ทุกไฟล์ที่แก้หรือสร้าง
- ถ้าต้องมี migration ให้เขียนมาด้วย
- อย่าเพิ่ง refactor อย่างอื่นที่ไม่ได้ขอ
## เป้าหมาย

หน้า index กับ show ของ Post ที่คนอ่านรู้เรื่อง
ใช้ partial ร่วมกัน และมีข้อมูลตัวอย่างพอให้เห็นปัญหา

## ข้อกำหนด

- partial app/views/posts/_post.html.erb
  รับค่าผ่าน local ห้ามใช้ instance variable
- index ใช้ render @posts ไม่ต้องเขียน each เอง
- โชว์ชื่อหมวด ไม่ใช่ category_id
- ตัดคำอธิบายด้วย truncate ไม่ใช่ substring
- แสดงเวลาด้วย time_ago_in_words
- index ต้องมี pagination หน้าละ 10
- controller ต้อง includes(:category)
- show มี breadcrumb กลับไปหน้า index
- db/seeds.rb สร้าง 5 หมวด 30 โพสต์ ข้อความไทย

## ห้าม

- ใช้ raw หรือ html_safe กับข้อมูลจากผู้ใช้
- Post.all ที่ไม่มี limit
- เขียน path เป็น string เช่น "/posts/#{id}"
- แตะ @post ข้างใน partial

## เกณฑ์ตรวจรับ

- [ ] เปิด /posts แล้วเห็นรายการพร้อมชื่อหมวด
- [ ] log โชว์ไม่เกิน 3 query ต่อการโหลด 1 หน้า
- [ ] partial ไม่มีคำว่า @ อยู่เลย
- [ ] grep หาคำว่า raw กับ html_safe แล้วไม่เจอ
- [ ] มี pagination ใช้งานได้จริง
- [ ] seed รันซ้ำได้ไม่พัง
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
## เป้าหมาย

login ผ่าน Keycloak ได้จริง comment ผูกกับ user จริง และคนอื่นแก้ของเราไม่ได้

## ข้อกำหนด

- omniauth-keycloak + omniauth-rails_csrf_protection realm wongnok · client wongnok-blog (confidential)
- KEYCLOAK_URL จาก env · client secret ใน rails credentials
- User หา-หรือ-สร้าง จาก sub ของ Keycloak ไม่ใช่จากอีเมล
- reset_session ก่อนเซ็ต session[:user_id] ทุกครั้ง
- rate_limit to: 10, within: 3.minutes ที่ sessions#create
- ย้าย comments.author_name -> user_id ด้วย expand-contract แยก migration คนละไฟล์ · รอบนี้หยุดที่ขั้นอ่านสองทาง
- Comment#author_label คืน user&.name || author_name แล้วให้ view เรียกเมธอดนี้ ไม่เรียก author_name ตรง ๆ
- controller ดึงของผ่าน current_user.posts.find
- PostPolicy / CommentPolicy เป็นคลาส Ruby ธรรมดา เจ้าของ หรือ admin เท่านั้น · ปฏิเสธด้วย 404 ไม่ใช่ 403

## ห้าม

- ตรวจสิทธิ์ใน view อย่างเดียว (ซ่อนปุ่มไม่ใช่ด่าน)
- user_id หรือ role อยู่ใน params.expect
- ส่ง access token ออกไปฝั่งเบราว์เซอร์
- ใช้ Current ใน job
- ปิด CSRF ทั้งแอป
- drop_column หรือ remove_column ในรอบนี้
- ใช้ Devise

## เกณฑ์ตรวจรับ

- [ ] login เป็น somchai ได้ · comment เก่า 30 อันยังมีชื่อถูก
- [ ] comments มีทั้ง author_name และ user_id อยู่พร้อมกัน และไม่มีแถวไหนที่ user_id เป็น null
- [ ] login เป็น malee แล้วเปิด /posts/1/edit ของ somchai -> 404
- [ ] ยิง PATCH ตรง ๆ ด้วย curl -> ไม่สำเร็จ และ DB ไม่เปลี่ยน
- [ ] login เป็น boss -> แก้โพสต์ของ somchai ได้ เพราะเป็น admin
- [ ] grep -rn "wongnok-dev-secret" app config -> ไม่เจอ
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
