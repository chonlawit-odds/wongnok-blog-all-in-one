# บันทึกว่า "โพสต์นี้ส่งอีเมลแจ้งคนนี้แล้ว" ใช้เป็นตัวจองสิทธิ์ส่งใน PublishPostJob
# ไม่มี validates uniqueness: สร้างด้วย insert_all ... ON CONFLICT DO NOTHING เท่านั้น
# unique index (post_id, follower_id) ที่ DB เป็นตัวตัดสินว่าใครได้ส่ง (validation เช็กแล้วยังชนกันได้ระหว่างสอง worker)
# อยากรู้ว่าแจ้งไปกี่คน: นับจากตารางนี้ ไม่เก็บตัวนับที่บวกเพิ่มทีละ 1 (job รันซ้ำแล้วเลขเพี้ยน)
class PostNotification < ApplicationRecord
  belongs_to :post
  belongs_to :follower
end
