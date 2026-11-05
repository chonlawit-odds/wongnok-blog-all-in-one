class AddPublishingCheckConstraintsToPosts < ActiveRecord::Migration[8.1]
  # กฎของ model ต้องมีที่ DB คู่กัน (เหมือน presence คู่ NOT NULL) แต่เป็นแบบมีเงื่อนไขตามสถานะ จึงใช้ check constraint
  # validate: false = NOT VALID: ไม่สแกนแถวเดิมตอนนี้ (ไม่ล็อกนาน) แต่แถวที่ insert/update ใหม่โดนตรวจทันที
  # สแกนแถวเดิมใน migration ถัดไป (VALIDATE CONSTRAINT ไม่บล็อกการอ่าน/เขียน)
  def change
    add_check_constraint :posts, "status IN ('draft', 'scheduled', 'published')",
                         name: "posts_status_valid", validate: false
    add_check_constraint :posts, "status <> 'scheduled' OR scheduled_at IS NOT NULL",
                         name: "posts_scheduled_requires_scheduled_at", validate: false
    add_check_constraint :posts, "status <> 'published' OR published_at IS NOT NULL",
                         name: "posts_published_requires_published_at", validate: false
  end
end
