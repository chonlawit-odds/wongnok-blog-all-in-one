# เผยแพร่โพสต์หนึ่งโพสต์ (ถ้าถึงเวลาแล้ว) แล้วส่งอีเมลแจ้งผู้ติดตาม
# ห้ามสมมติว่ารันครั้งเดียว: ตัวกวาดอาจเข้าคิวซ้ำทุกนาที, retry, หรือสอง worker หยิบพร้อมกัน
# - สถานะ: Post#publish_if_due! ล็อกแถวแล้วเช็กสถานะก่อนเปลี่ยน
# - อีเมล: unique index (post_id, follower_id) ของ post_notifications จองสิทธิ์ส่งได้คนละครั้ง
# รันซ้ำกี่รอบสถานะก็ไม่เปลี่ยน และไม่มีอีเมลเพิ่ม  ถ้ารอบก่อนพังกลางทาง รอบนี้ส่งต่อเฉพาะคนที่ยังไม่ได้
class PublishPostJob < ApplicationJob
  queue_as :default

  FOLLOWERS_BATCH_SIZE = 1_000

  # error ชั่วคราวของ DB: ลองใหม่โดยเว้นระยะถ่างออกเรื่อย ๆ (ราว 3s, 18s, 83s, 258s + jitter)
  # retry ได้อย่างปลอดภัยเพราะ job นี้ idempotent
  retry_on ActiveRecord::Deadlocked, ActiveRecord::LockWaitTimeout, ActiveRecord::ConnectionNotEstablished,
           wait: :polynomially_longer, attempts: 5
  # โพสต์ถูกลบไปก่อนถึงคิว: ไม่มีอะไรให้เผยแพร่ ทิ้งงานไปเลย retry ไปก็ไม่มีวันเจอ
  discard_on ActiveRecord::RecordNotFound

  # รับแค่ id: โหลดสดจาก DB ทุกครั้ง ไม่เชื่อสถานะ/เวลาที่อาจเก่าไปแล้วตอนเข้าคิว
  def perform(post_id)
    post = Post.find(post_id)
    post.publish_if_due!
    notify_followers(post) if post.published?
  end

  private
    # เฉพาะคนที่ติดตามก่อนเวลาเผยแพร่: รันซ้ำทีหลังจะไม่ส่งโพสต์เก่าไปหาคนที่เพิ่งมาติดตาม
    def notify_followers(post)
      Follower.where(created_at: ..post.published_at).in_batches(of: FOLLOWERS_BATCH_SIZE) do |followers|
        rows = followers.ids.map { |follower_id| { post_id: post.id, follower_id: } }

        # จองก่อนส่ง: ON CONFLICT DO NOTHING คืนมาเฉพาะแถวที่เราใส่ได้จริง
        # แถวที่รอบก่อน/worker อื่นจองไปแล้วไม่ถูกคืนมา จึงไม่มีใครส่งซ้ำ
        # จองกับเข้าคิวอีเมลอยู่ใน transaction เดียว: เข้าคิวพัง = การจองถูกยกเลิก retry รอบหน้าค่อยส่ง ไม่หายเงียบ
        PostNotification.transaction do
          claimed = PostNotification.insert_all(rows, unique_by: %i[ post_id follower_id ], returning: :follower_id)

          # ส่งแค่ id เข้า job อีเมล: ลิงก์และเนื้อหาสร้างตอนส่งจริงใน PostMailer
          claimed.rows.each do |(follower_id)|
            PostMailer.with(post_id: post.id, follower_id:).published.deliver_later
          end
        end
      end
    end
end
