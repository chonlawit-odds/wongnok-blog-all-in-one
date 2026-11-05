class CreatePostNotifications < ActiveRecord::Migration[8.1]
  # หนึ่งแถว = "โพสต์นี้ส่งอีเมลหาคนนี้แล้ว (หรือมี worker จองไว้แล้ว)"
  def change
    create_table :post_notifications do |t|
      # index แยกของ post_id ไม่ต้องมี: unique index ด้านล่างขึ้นต้นด้วย post_id
      t.references :post, null: false, foreign_key: true, index: false
      t.references :follower, null: false, foreign_key: true

      t.timestamps
    end

    # กันสอง worker (หรือ job ที่รันซ้ำ) ส่งอีเมลโพสต์เดียวกันหาคนเดิมซ้ำ:
    # ใครใส่แถวได้ก่อนคนนั้นส่ง อีกคน INSERT ... ON CONFLICT DO NOTHING แล้วไม่ได้แถวคืน
    add_index :post_notifications, %i[ post_id follower_id ], unique: true
  end
end
