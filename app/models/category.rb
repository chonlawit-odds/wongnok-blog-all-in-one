class Category < ApplicationRecord
  has_many :posts, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 80 }
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/, message: "ใช้ได้เฉพาะ a-z, 0-9 และขีด" }

  before_validation :generate_slug
  scope :alphabetical, -> { order(:name) }

  private
  def generate_slug
    self.slug = slug.presence || name.to_s.parameterize
  end
end
