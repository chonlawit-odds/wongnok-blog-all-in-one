# ตัวกวาด: รันทุกนาทีจาก config/recurring.yml หาโพสต์ที่ถึงเวลาแล้วส่งต่อให้ PublishPostJob ทีละโพสต์
# ไม่ใช้ PublishPostJob.set(wait_until: scheduled_at) ตอนบันทึก เพราะผู้ใช้แก้/ยกเลิกเวลาได้
# (งานที่ตั้งไว้กับเวลาเก่าจะค้างอยู่ในคิว) ตัวกวาดอ่านเวลาล่าสุดจาก DB เสมอ
# รอบนี้พลาด รอบหน้ากวาดเจออีก  เข้าคิวซ้ำก็ไม่เป็นไร เพราะ PublishPostJob idempotent
class PublishDuePostsJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 500

  def perform
    Post.due_for_publishing.in_batches(of: BATCH_SIZE) do |posts|
      # แยก job ต่อโพสต์: โพสต์หนึ่งพังไม่ลากโพสต์อื่น และ retry เฉพาะตัวที่พัง  ส่งแค่ id
      ActiveJob.perform_all_later(posts.ids.map { |post_id| PublishPostJob.new(post_id) })
    end
  end
end
