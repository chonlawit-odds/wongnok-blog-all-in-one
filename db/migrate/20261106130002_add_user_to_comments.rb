class AddUserToComments < ActiveRecord::Migration[8.1]
  # expand ของการย้าย comments.author_name -> user_id  (รอบนี้หยุดที่ขั้น "อ่านสองทาง")
  #   1. migration นี้: เพิ่ม user_id แบบ nullable (แถวเดิมยังไม่มีเจ้าของ) แก้แค่ catalog ไม่ rewrite ตาราง
  #   2. โค้ดเขียนทั้งสองคอลัมน์: comment ใหม่มี user_id + author_name (สำเนาชื่อ user)
  #   3. backfill แถวเดิม (migration ถัดไป)
  #   4. อ่านสองทาง: Comment#author_label = user&.name || author_name
  #   รอบหน้า (contract): user_id NOT NULL, เลิกเขียน author_name แล้วค่อยลบคอลัมน์
  # - index แบบ concurrently ไม่ล็อกการเขียน (ต้องอยู่นอก transaction)
  # - foreign key แบบ NOT VALID: ตรวจแถวที่เขียนใหม่ทันที แต่ไม่สแกนแถวเดิมตอนนี้ (validate ใน migration แยก)
  disable_ddl_transaction!

  def change
    add_reference :comments, :user, index: { algorithm: :concurrently }
    # แยก foreign key ออกจาก add_reference: ถ้าเขียน foreign_key: { validate: false } รวมไว้
    # rollback จะหา FK ที่ validate: false ไม่เจอ (migration ถัดไป validate ไปแล้ว) แล้วพัง
    reversible do |direction|
      direction.up { add_foreign_key :comments, :users, validate: false }
      direction.down { remove_foreign_key :comments, :users }
    end
  end
end
