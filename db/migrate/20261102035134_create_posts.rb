class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.text :description, null: false
      t.references :category, null: false, foreign_key: true

      t.timestamps

      t.index :created_at
    end
  end
end
