class BackfillPostsPublishedAt < ActiveRecord::Migration[8.1]
  # expand-contract ขั้น backfill: โพสต์เดิมถือว่าเผยแพร่ตั้งแต่ตอนสร้าง
  # - ทำทีละ batch นอก transaction ใหญ่ ไม่ล็อกตาราง posts ทั้งตารางระหว่าง backfill
  # - รันซ้ำได้: เลือกเฉพาะแถวที่ published_at ยังว่าง
  disable_ddl_transaction!

  BATCH_SIZE = 1_000

  # model เฉพาะของ migration: ไม่ผูกกับ app/models/post.rb ที่จะเปลี่ยนไปในอนาคต
  class MigrationPost < ActiveRecord::Base
    self.table_name = "posts"
  end

  def up
    MigrationPost.where(status: "published", published_at: nil).in_batches(of: BATCH_SIZE) do |posts|
      posts.update_all("published_at = created_at")
    end
  end

  # ไม่มีอะไรต้องย้อน: คอลัมน์จะหายไปเองถ้า rollback migration ที่เพิ่มคอลัมน์
  def down
  end
end
