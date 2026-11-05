class Post < ApplicationRecord
  COVER_CONTENT_TYPES = %w[ image/png image/jpeg image/webp ].freeze
  COVER_MAX_SIZE = 5.megabytes
  # magic bytes ของ png/jpeg/webp อยู่ใน 12 byte แรก อ่านเผื่อไว้เท่ากับที่ Active Storage ใช้
  COVER_HEADER_SIZE = 4.kilobytes

  belongs_to :category
  # ลบโพสต์ = comment หมดความหมาย ลบตามด้วย SQL เดียว
  # (comment ไม่มีของที่ต้องเก็บกวาดต่อ และหน้าโพสต์หายไปแล้ว ไม่ต้อง broadcast ลบทีละอัน)
  has_many :comments, dependent: :delete_all
  # ประวัติว่าส่งอีเมลแจ้งใครไปแล้ว ลบโพสต์ = ไม่มีความหมายแล้ว ลบด้วย SQL เดียว
  has_many :post_notifications, dependent: :delete_all
  # Action Text ผูก has_one :rich_text_body, dependent: :destroy ให้เอง (ลบโพสต์ = ลบเนื้อหาด้วย)
  has_rich_text :body
  # ลบโพสต์ = ไฟล์ไม่มีใครใช้แล้ว ลบออกจาก MinIO ผ่าน job ไม่ให้ request รอ
  has_one_attached :cover, dependent: :purge_later do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 400, 300 ]
    attachable.variant :large, resize_to_limit: [ 1200, 800 ]
  end

  # เก็บเป็น string อ่านใน SQL ได้ตรง ๆ  DB มี check constraint ค่าที่ยอมรับคู่กัน
  # published ได้ทางเดียวคือ publish_if_due! (เรียกจาก PublishPostJob) ฟอร์มส่ง published_at มาไม่ได้
  enum :status, { draft: "draft", scheduled: "scheduled", published: "published" }, default: :draft, validate: true

  validates :title, presence: true, length: { maximum: 120 }
  validates :body, presence: true
  # presence แบบมีเงื่อนไข คู่กับ check constraint posts_*_requires_* ที่ DB
  validates :scheduled_at, presence: true, if: :scheduled?
  validates :published_at, presence: true, if: :published?
  validate :scheduled_at_cannot_be_in_the_past, if: -> { scheduled? && scheduled_at? && (will_save_change_to_scheduled_at? || will_save_change_to_status?) }
  validate :cover_must_be_an_allowed_image, if: -> { attachment_changes["cover"].present? && cover.attached? }

  before_save :sync_plain_text, if: -> { body.changed? }

  scope :recent, -> { order(created_at: :desc) }
  scope :latest_published, -> { published.order(published_at: :desc) }
  # ใช้ partial index ของ scheduled_at (WHERE status = 'scheduled')
  scope :due_for_publishing, ->(now = Time.current) { scheduled.where(scheduled_at: ..now) }

  # guard สถานะ: เปลี่ยนเป็น published เฉพาะโพสต์ที่ scheduled และถึงเวลาแล้วเท่านั้น
  # with_lock = SELECT ... FOR UPDATE แล้ว reload: ตัดสินจากค่าล่าสุดใน DB ไม่ใช่ค่าเก่าตอนเข้าคิว
  # (ผู้ใช้เลื่อนเวลาออกไปหลัง job เข้าคิวแล้ว -> ยังไม่ถึงเวลา ไม่เผยแพร่)
  # worker สองตัวมาพร้อมกัน ตัวที่สองรอ lock แล้วเห็นว่า published ไปแล้ว จึงไม่ทำซ้ำ
  # คืน true เฉพาะรอบที่เปลี่ยนสถานะจริง
  def publish_if_due!(now = Time.current)
    with_lock do
      next false unless scheduled? && scheduled_at <= now

      update!(status: :published, published_at: now)
    end
  end

  private
    # datetime-local เลือกได้ถึงระดับนาที จึงยอมให้เลือก "นาทีนี้" ได้ (เผยแพร่รอบกวาดถัดไป)
    def scheduled_at_cannot_be_in_the_past
      errors.add(:scheduled_at, :in_the_past) if scheduled_at < Time.current.beginning_of_minute
    end

    # plain_text ไว้ค้นหาภายหลัง
    # expand-contract: description ยัง NOT NULL และโค้ดรุ่นก่อนยังอ่านอยู่ (เผื่อ rollback) จึงเขียนคู่กันไปก่อน
    # รอบ contract ค่อยเลิกเขียน description แล้วลบคอลัมน์
    def sync_plain_text
      self.plain_text = body.to_plain_text
      self.description = plain_text
    end

    def cover_must_be_an_allowed_image
      if cover.blob.byte_size > COVER_MAX_SIZE
        errors.add(:cover, :file_too_large, size: ActiveSupport::NumberHelper.number_to_human_size(COVER_MAX_SIZE))
      end

      # ดูชนิดไฟล์จาก magic bytes อย่างเดียว ไม่ส่งชื่อไฟล์/content_type ของ client ให้ Marcel
      # (Active Storage เดาโดยใช้ชื่อไฟล์ประกอบ .txt ที่เปลี่ยนเป็น .png จึงได้ image/png)
      # และ content_type ที่บันทึกไว้ต้องตรงกับเนื้อไฟล์ด้วย ไม่งั้นทำ variant ไม่ได้
      detected = Marcel::MimeType.for(StringIO.new(cover_header))
      unless COVER_CONTENT_TYPES.include?(detected) && cover.content_type == detected
        errors.add(:cover, :invalid_image_type)
      end
    end

    def cover_header
      case attachable = attachment_changes["cover"].attachable
      when ActiveStorage::Blob, String
        # direct upload: ไฟล์อยู่บน MinIO แล้ว ดึงมาเฉพาะช่วงหัวไฟล์ (range request) ไม่โหลดทั้งไฟล์
        cover.blob.download_chunk(0...COVER_HEADER_SIZE)
      else
        # ไฟล์ที่ส่งมากับฟอร์ม/API ยังไม่ได้อัปขึ้น storage: อ่านจาก io ตรง ๆ แล้ว rewind คืน
        io = attachable.is_a?(Hash) ? attachable.fetch(:io) : attachable
        io.rewind
        io.read(COVER_HEADER_SIZE).to_s.tap { io.rewind }
      end
    end
end
