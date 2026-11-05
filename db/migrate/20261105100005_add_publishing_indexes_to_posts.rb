class AddPublishingIndexesToPosts < ActiveRecord::Migration[8.1]
  # concurrently: สร้าง index โดยไม่ล็อกการเขียนตาราง posts (ต้องอยู่นอก transaction)
  disable_ddl_transaction!

  def change
    # PublishDuePostsJob กวาดทุกนาที: WHERE status = 'scheduled' AND scheduled_at <= now
    # partial index เก็บเฉพาะโพสต์ที่รอเผยแพร่ index จึงเล็กมากแม้โพสต์ทั้งหมดจะเยอะ
    add_index :posts, :scheduled_at, where: "status = 'scheduled'", algorithm: :concurrently
    # หน้ารายการ: WHERE status = 'published' ORDER BY published_at DESC LIMIT 10
    add_index :posts, :published_at, where: "status = 'published'", algorithm: :concurrently
  end
end
