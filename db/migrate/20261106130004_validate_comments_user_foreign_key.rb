class ValidateCommentsUserForeignKey < ActiveRecord::Migration[8.1]
  # สแกนแถวเดิมว่า user_id ชี้ไปที่ users จริง (หลัง backfill)
  # VALIDATE CONSTRAINT ไม่บล็อกการอ่าน/เขียน comments ระหว่างตรวจ
  def change
    validate_foreign_key :comments, :users
  end
end
