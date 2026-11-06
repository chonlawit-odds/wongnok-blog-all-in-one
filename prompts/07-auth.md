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
