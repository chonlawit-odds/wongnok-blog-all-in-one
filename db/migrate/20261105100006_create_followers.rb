class CreateFollowers < ActiveRecord::Migration[8.1]
  def change
    create_table :followers do |t|
      t.string :email, null: false

      t.timestamps
    end

    # validates uniqueness คู่ unique index (model normalizes เป็นตัวเล็กก่อนบันทึก)
    add_index :followers, :email, unique: true
    # PublishPostJob เลือกเฉพาะคนที่ติดตามก่อนเวลาเผยแพร่ (created_at <= published_at)
    add_index :followers, :created_at
  end
end
