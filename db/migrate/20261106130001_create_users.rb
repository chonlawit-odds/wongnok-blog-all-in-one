class CreateUsers < ActiveRecord::Migration[8.1]
  # ตารางใหม่ ยังไม่มีข้อมูล จึงใส่ NOT NULL / index / check constraint ได้ทันทีโดยไม่ล็อกใคร
  def change
    create_table :users do |t|
      # sub ของ Keycloak = ตัวตนของผู้ใช้ (ไม่เปลี่ยนตลอดอายุบัญชี) หา-หรือ-สร้างผู้ใช้จากคอลัมน์นี้เท่านั้น ไม่ใช่จากอีเมล
      # NULL = ผู้ใช้เดิมที่สร้างจาก comments.author_name ตอนย้ายข้อมูล ไม่มีบัญชี Keycloak จึงไม่มีใคร login เป็นคนนี้ได้
      t.string :keycloak_sub
      t.string :name, null: false
      t.string :email
      # ค่าตาม realm role ของ Keycloak ทุกครั้งที่ login
      t.string :role, null: false, default: "author"
      t.timestamps
    end

    add_index :users, :keycloak_sub, unique: true
    # ผู้ใช้เดิม 1 ชื่อ = 1 แถว: backfill ใช้ INSERT ... ON CONFLICT DO NOTHING จองชื่อ รันซ้ำแล้วไม่สร้างซ้ำ
    add_index :users, :name, unique: true, where: "keycloak_sub IS NULL", name: "index_users_on_name_without_keycloak_sub"
    add_check_constraint :users, "role IN ('author', 'admin')", name: "users_role_valid"
  end
end
