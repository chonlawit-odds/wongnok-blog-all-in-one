# wongnok_blog

@prompts/00-context.md

## คำสั่งที่ใช้บ่อย

- bin/dev                 รัน web + tailwind watch
- bin/rails test          รัน test ทั้งหมด
- bin/rails db:prepare    เตรียมฐานข้อมูล
- bin/rails routes        ดู route ทั้งหมด
- docker compose up -d    postgres + minio
- bin/check               rubocop + brakeman + zeitwerk:check + test (หยุดที่ตัวแรกที่ fail)
- bin/rails test:system   system test (ต้องมี Chrome) CI รันแยกอีก job

## Definition of done

- ก่อนบอกว่า "เสร็จ" ต้องรัน `bin/check` เองและผ่านทั้งหมด (exit 0) แล้วรายงานผลจริง ไม่ใช่เดาว่าน่าจะผ่าน
- แก้ส่วนที่มี system test (comment สด, แก้หัวข้อ inline) ต้องรัน `bin/rails test:system` ด้วย
- ห้ามแก้ `.rubocop.yml` (หรือใส่ `rubocop:disable`) เพื่อให้ผ่าน ต้องแก้โค้ดให้ถูก style
