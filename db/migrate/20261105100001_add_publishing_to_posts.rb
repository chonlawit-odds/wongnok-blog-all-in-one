class AddPublishingToPosts < ActiveRecord::Migration[8.1]
  # expand: ทุกคำสั่งแก้แค่ catalog ไม่ rewrite ตาราง posts (PostgreSQL 11+ เก็บ default ที่เป็นค่าคงที่ไว้ใน catalog)
  # - status ใส่ default "published" ก่อน: โพสต์เดิมทุกแถวยังโชว์อยู่เหมือนเดิมทันที ไม่ต้อง UPDATE ทั้งตาราง
  #   แล้วค่อยเปลี่ยน default เป็น "draft" ให้โพสต์ใหม่เริ่มเป็นฉบับร่าง
  # - scheduled_at / published_at เป็น nullable ไม่มี default  published_at ของโพสต์เดิม backfill ใน migration ถัดไป
  def change
    add_column :posts, :status, :string, null: false, default: "published"
    change_column_default :posts, :status, from: "published", to: "draft"
    add_column :posts, :scheduled_at, :datetime
    add_column :posts, :published_at, :datetime
  end
end
