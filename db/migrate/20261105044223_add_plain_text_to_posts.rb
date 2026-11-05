class AddPlainTextToPosts < ActiveRecord::Migration[8.1]
  # expand: เพิ่มคอลัมน์ใหม่แบบ nullable ไม่มี default -> PostgreSQL แก้แค่ catalog ไม่ rewrite ตาราง ไม่ล็อกนาน
  # เก็บข้อความล้วนของ body ไว้ค้นหาภายหลัง (index สำหรับค้นหาค่อยเพิ่มตอนทำ search จริง แบบ concurrently)
  def change
    add_column :posts, :plain_text, :text
  end
end
