class BackfillCommentsUserId < ActiveRecord::Migration[8.1]
  # comment เดิมเขียนก่อนมีระบบ login มีแค่ชื่อที่พิมพ์เอง (author_name)
  # สร้าง "ผู้ใช้เดิม" 1 คนต่อ 1 ชื่อ (keycloak_sub = NULL login ไม่ได้) แล้วผูก comment เข้ากับคนนั้น
  # - ชื่อย้ายไปอยู่ที่ users.name ครบทุกแถว: author_label ได้ชื่อเดิม และรอบ contract ลบ author_name ได้โดยชื่อไม่หาย
  # - ไม่ผูกกับบัญชี Keycloak ที่ชื่อเหมือนกัน: ชื่อที่พิมพ์เองไม่ใช่หลักฐานว่าเป็นคนเดียวกัน
  # ทีละ batch แต่ละ batch commit เอง ไม่ล็อก comments ทั้งตารางจนจบ
  # รันซ้ำได้: เลือกเฉพาะแถวที่ user_id ยังว่าง และจองชื่อด้วย unique index + ON CONFLICT DO NOTHING
  disable_ddl_transaction!

  BATCH_SIZE = 1_000

  # model เฉพาะ migration ไม่ผูกกับ app/models (callback/validation ของ app เปลี่ยนได้ในอนาคต)
  class MigrationComment < ActiveRecord::Base
    self.table_name = "comments"
  end

  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  def up
    MigrationComment.where(user_id: nil).in_batches(of: BATCH_SIZE) do |comments|
      MigrationComment.transaction do
        rows = comments.distinct.pluck(:author_name).map { |name| { name:, role: "author" } }
        MigrationUser.insert_all(rows, unique_by: :index_users_on_name_without_keycloak_sub) if rows.any?

        # ไม่แตะ updated_at: เจ้าของเดิมคนเดิม ชื่อที่โชว์ก็เหมือนเดิม ไม่ใช่การแก้ comment
        comments.update_all(<<~SQL.squish)
          user_id = (SELECT users.id FROM users
                     WHERE users.keycloak_sub IS NULL AND users.name = comments.author_name)
        SQL
      end
    end
  end

  # rollback ต่อด้วย migration ก่อนหน้าที่ลบคอลัมน์ user_id (และตาราง users) ทิ้งอยู่แล้ว
  def down
  end
end
