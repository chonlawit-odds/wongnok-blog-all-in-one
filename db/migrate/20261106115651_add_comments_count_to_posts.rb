class AddCommentsCountToPosts < ActiveRecord::Migration[8.1]
  # expand: เพิ่มคอลัมน์ตัวนับให้ counter_cache ของ Comment belongs_to :post ก่อน แล้วเติมค่าเดิมใน migration ถัดไป
  # PostgreSQL 11+ เพิ่มคอลัมน์ที่ default เป็นค่าคงที่ได้โดยไม่ rewrite ตาราง (เก็บ default ไว้ใน catalog)
  # จึงล็อกแค่ชั่วพริบตาแม้ posts จะมีหลายล้านแถว  NOT NULL คู่กับ default 0 ได้ทันทีเพราะทุกแถวได้ 0
  def change
    add_column :posts, :comments_count, :integer, default: 0, null: false
  end
end
