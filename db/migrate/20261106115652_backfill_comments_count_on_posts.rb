class BackfillCommentsCountOnPosts < ActiveRecord::Migration[8.1]
  # ไม่ห่อทั้ง migration ใน transaction เดียว: แต่ละ batch commit เอง ล็อกแถวทีละ 1,000 แถวแล้วปล่อย
  # (ห่อรวมกัน = ล็อกทุกแถวของ posts ไว้จนจบ ระหว่างนั้นเพิ่ม comment ไม่ได้เลย)
  disable_ddl_transaction!

  # model เฉพาะ migration ไม่ผูกกับ app/models/post.rb (callback/validation ของ app เปลี่ยนได้ในอนาคต)
  class MigrationPost < ActiveRecord::Base
    self.table_name = "posts"
  end

  # นับใหม่จากตาราง comments ด้วย UPDATE เดียวต่อ batch ไม่วนทีละแถว (ไม่ใช้ reset_counters)
  # คำนวณจากของจริงทุกครั้ง รันซ้ำกี่รอบก็ได้ค่าถูก (เช่น มี comment เข้ามาระหว่าง deploy ก่อนโค้ดใหม่ขึ้น)
  # ไม่แตะ updated_at: ตัวเลขเท่ากับที่ควรเป็นอยู่แล้ว ไม่ใช่การแก้โพสต์
  def up
    MigrationPost.in_batches(of: 1_000) do |batch|
      batch.update_all(<<~SQL.squish)
        comments_count = (SELECT COUNT(*) FROM comments WHERE comments.post_id = posts.id)
      SQL
    end
  end

  # rollback ต่อด้วย migration ก่อนหน้าที่ลบคอลัมน์ทิ้งอยู่แล้ว ไม่มีอะไรต้องคืน
  def down
  end
end
