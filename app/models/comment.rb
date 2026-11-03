class Comment < ApplicationRecord
  AUTHOR_NAME_MAX_LENGTH = 50
  BODY_MAX_LENGTH = 1_000

  belongs_to :post

  # textarea ส่งขึ้นบรรทัดใหม่มาเป็น \r\n ทำให้ Ruby นับยาวกว่าที่ตัวนับในเบราว์เซอร์นับ
  normalizes :author_name, with: ->(name) { name.squish }
  normalizes :body, with: ->(body) { body.strip.gsub(/\r\n?/, "\n") }

  validates :author_name, presence: true, length: { maximum: AUTHOR_NAME_MAX_LENGTH }
  validates :body, presence: true, length: { maximum: BODY_MAX_LENGTH }

  scope :chronological, -> { order(:created_at) }

  # real-time: ทุกแท็บที่เปิดหน้าโพสต์นี้ (turbo_stream_from post) ได้ comment ใหม่ต่อท้ายรายการ
  # broadcasts_to ผูกกับ after_*_commit และส่งตอน create/update ผ่าน job (broadcast_*_later_to) อยู่แล้ว
  broadcasts_to :post, target: ->(comment) { [ comment.post, :comments ] }

  # ตัวนับจำนวน comment ของทุกแท็บ  after_commit ไม่ใช่ after_save: job ต้องเห็นแถวที่ commit แล้ว
  after_create_commit :broadcast_comments_count

  private
    # ยิงผ่าน post เพื่อให้ locals เป็น { post: } ตรงกับ strict locals ของ comments/_count
    def broadcast_comments_count
      post.broadcast_update_later_to post, target: [ post, :comments_count ], partial: "comments/count"
    end
end
