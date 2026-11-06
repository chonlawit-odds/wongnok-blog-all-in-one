class AddUserToPosts < ActiveRecord::Migration[8.1]
  # เจ้าของโพสต์ (controller หาโพสต์ที่จะแก้จาก current_user.posts)
  # nullable: โพสต์เดิมเขียนก่อนมีระบบ login ไม่มีข้อมูลว่าใครเขียน จึงยังไม่มีเจ้าของ = แก้ได้เฉพาะ admin
  # โพสต์ใหม่มี user_id เสมอ  NOT NULL ค่อยใส่รอบหน้าหลังกำหนดเจ้าของให้โพสต์เดิมครบ
  # index concurrently + foreign key NOT VALID แบบเดียวกับ comments (ดู AddUserToComments)
  disable_ddl_transaction!

  def change
    add_reference :posts, :user, index: { algorithm: :concurrently }
    reversible do |direction|
      direction.up { add_foreign_key :posts, :users, validate: false }
      direction.down { remove_foreign_key :posts, :users }
    end
  end
end
