class Follower < ApplicationRecord
  EMAIL_MAX_LENGTH = 254

  # เลิกติดตาม = ประวัติการแจ้งเตือนของคนนี้ไม่มีความหมายแล้ว ลบด้วย SQL เดียว
  has_many :post_notifications, dependent: :delete_all

  # unique index ที่ DB เทียบตรงตัว จึงทำให้เป็นตัวเล็กก่อนเสมอ (A@x.com กับ a@x.com คือคนเดียวกัน)
  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :email, presence: true, uniqueness: true, length: { maximum: EMAIL_MAX_LENGTH },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
end
