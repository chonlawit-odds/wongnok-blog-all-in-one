class Post < ApplicationRecord
  belongs_to :category
  # ลบโพสต์ = comment หมดความหมาย ลบตามด้วย SQL เดียว
  # (comment ไม่มีของที่ต้องเก็บกวาดต่อ และหน้าโพสต์หายไปแล้ว ไม่ต้อง broadcast ลบทีละอัน)
  has_many :comments, dependent: :delete_all

  validates :title, presence: true, length: { maximum: 120 }
  validates :description, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
