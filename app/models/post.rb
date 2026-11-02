class Post < ApplicationRecord
  belongs_to :category

  validates :title, presence: true, length: { maximum: 120 }
  validates :description, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
