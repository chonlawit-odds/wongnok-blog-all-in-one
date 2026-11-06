class Category < ApplicationRecord
  has_many :posts, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 80 }
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/, message: "ใช้ได้เฉพาะ a-z, 0-9 และขีด" }

  before_validation :generate_slug
  # ชื่อหมวดหมู่อยู่ในการ์ดโพสต์ที่ cache ไว้ (key = โพสต์ + updated_at) แต่โพสต์ไม่รู้ว่าหมวดหมู่เปลี่ยนชื่อ
  # จึง touch โพสต์ทั้งหมวดให้ด้วย UPDATE เดียว การ์ดได้ key ใหม่เอง ไม่ต้องลบ cache
  # after_update ไม่ใช่ after_commit: เป็นแค่การเขียน DB ให้ commit พร้อมกับการเปลี่ยนชื่อ (ไม่ได้ยิงงานต่อ)
  after_update :touch_posts, if: :saved_change_to_name?
  scope :alphabetical, -> { order(:name) }

  private
  def generate_slug
    self.slug = slug.presence || name.to_s.parameterize
  end

  def touch_posts
    posts.touch_all
  end
end
