class Comment < ApplicationRecord
  AUTHOR_NAME_MAX_LENGTH = 50
  BODY_MAX_LENGTH = 1_000

  # touch: เพิ่ม/แก้/ลบ comment = updated_at ของโพสต์เปลี่ยน -> cache key ของการ์ดโพสต์ใบนั้น (และรายการที่ครอบอยู่) เปลี่ยนเอง
  #        ไม่ต้องลบ cache เอง  การ์ดใบอื่นใน cache ยังใช้ได้ (Russian doll)
  # counter_cache: เก็บจำนวน comment ไว้ที่ posts.comments_count นับให้ตอน create/destroy
  #        หน้ารายการโชว์จำนวนได้โดยไม่ COUNT ทีละโพสต์ (N+1)
  belongs_to :post, touch: true, counter_cache: true

  # ย้าย author_name -> user_id แบบ expand-contract  รอบนี้หยุดที่ "อ่านสองทาง"
  # - เขียน: comment ใหม่มีทั้ง user และ author_name (สำเนาชื่อ user) เพราะ author_name ยัง NOT NULL
  #   และโค้ดรุ่นก่อนที่ยังรันอยู่ระหว่าง deploy ยังอ่านคอลัมน์นี้
  # - อ่าน: author_label (view เรียกเมธอดนี้ ไม่เรียก author_name ตรง ๆ)
  # - รอบ contract: user_id NOT NULL แล้วเอา optional ออก, เลิกเขียน author_name แล้วค่อยลบคอลัมน์
  # optional: DB ยังยอม NULL (validates presence ต้องคู่ NOT NULL)  controller ใส่ current_user ให้ทุกครั้ง
  belongs_to :user, optional: true

  # ชื่อมาจากบัญชีที่ login ไม่ใช่จากฟอร์ม
  before_validation :copy_author_name_from_user, on: :create, if: :user

  # textarea ส่งขึ้นบรรทัดใหม่มาเป็น \r\n ทำให้ Ruby นับยาวกว่าที่ตัวนับในเบราว์เซอร์นับ
  normalizes :author_name, with: ->(name) { name.squish }
  normalizes :body, with: ->(body) { body.strip.gsub(/\r\n?/, "\n") }

  validates :author_name, presence: true, length: { maximum: AUTHOR_NAME_MAX_LENGTH }
  validates :body, presence: true, length: { maximum: BODY_MAX_LENGTH }

  scope :chronological, -> { order(:created_at) }

  # real-time: ทุกแท็บที่เปิดหน้าโพสต์นี้ (turbo_stream_from post) ได้ comment ใหม่ต่อท้ายรายการ
  # broadcasts_to ผูกกับ after_*_commit และส่งตอน create/update ผ่าน job (broadcast_*_later_to) อยู่แล้ว
  broadcasts_to :post, target: ->(comment) { [ comment.post, :comments ] }

  # ตัวนับจำนวน comment ของทุกแท็บ (ทั้งตอนเพิ่มและลบ)  after_commit ไม่ใช่ after_save: job ต้องเห็นแถวที่ commit แล้ว
  after_commit :broadcast_comments_count, on: %i[ create destroy ]

  # อ่านสองทาง: แถวที่มี user ใช้ชื่อจาก user (comment เดิมได้ผู้ใช้เดิมที่ชื่อเดียวกับ author_name จาก backfill)
  # แถวที่ยังไม่มี user (ระหว่าง deploy ก่อน backfill เสร็จ) ใช้ author_name เดิม
  def author_label
    user&.name || author_name
  end

  private
    def copy_author_name_from_user
      self.author_name = user.name.truncate(AUTHOR_NAME_MAX_LENGTH)
    end

    # ยิงผ่าน post เพื่อให้ locals เป็น { post: } ตรงกับ strict locals ของ comments/_count
    def broadcast_comments_count
      post.broadcast_update_later_to post, target: [ post, :comments_count ], partial: "comments/count"
    end
end
