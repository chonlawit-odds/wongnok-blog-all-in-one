class BackfillPostsBodyFromDescription < ActiveRecord::Migration[8.1]
  # expand-contract ขั้น backfill: ย้าย description (ข้อความล้วน) ไปเป็น body (Action Text) + plain_text
  # - ไม่ลบ/ไม่แก้ description รอบนี้ (โค้ดยังเขียน description คู่กันไปใน Post#sync_plain_text)
  # - ทำทีละ batch นอก transaction ใหญ่ ไม่ล็อกตาราง posts ทั้งตารางระหว่าง backfill
  # - รันซ้ำได้: เลือกเฉพาะแถวที่ plain_text ยังว่าง และ insert_all ข้ามแถวที่มี body อยู่แล้ว (unique index)
  disable_ddl_transaction!

  BATCH_SIZE = 1_000

  # model เฉพาะของ migration: ไม่ผูกกับ app/models/post.rb ที่จะเปลี่ยนไปในอนาคต
  class MigrationPost < ActiveRecord::Base
    self.table_name = "posts"
  end

  class MigrationRichText < ActiveRecord::Base
    self.table_name = "action_text_rich_texts"
  end

  def up
    MigrationPost.where(plain_text: nil).in_batches(of: BATCH_SIZE) do |posts|
      now = Time.current
      rows = posts.pluck(:id, :description).map do |id, description|
        { record_type: "Post", record_id: id, name: "body", body: to_trix_html(description), created_at: now, updated_at: now }
      end

      MigrationRichText.insert_all(rows, unique_by: %i[ record_type record_id name ])
      posts.update_all("plain_text = description")
    end
  end

  # ไม่มีอะไรต้องย้อน: description ยังอยู่ครบ  rich text จะหายไปเองถ้า rollback migration ที่สร้างตาราง
  def down
  end

  private
    # description เป็นข้อความล้วน: escape ก่อนเสมอ (โพสต์เดิมมีข้อความ <script> ที่ต้องโชว์เป็นตัวอักษร)
    # แล้วแปลงขึ้นบรรทัดใหม่เป็น <br> แบบเดียวกับที่ Trix เก็บย่อหน้า
    def to_trix_html(description)
      text = ERB::Util.html_escape(description.to_s.gsub(/\r\n?/, "\n"))
      "<div>#{text.gsub("\n", "<br>")}</div>"
    end
end
