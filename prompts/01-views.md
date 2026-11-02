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
