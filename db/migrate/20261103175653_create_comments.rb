class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      # index แยกของ post_id ไม่ต้องมี: composite index ด้านล่างขึ้นต้นด้วย post_id
      # ใช้ได้ทั้งตอนหา comment ของโพสต์ (foreign key) และตอนเรียงตามเวลา
      t.references :post, null: false, foreign_key: true, index: false
      t.string :author_name, null: false
      t.text :body, null: false

      t.timestamps
    end

    add_index :comments, %i[post_id created_at]
  end
end
