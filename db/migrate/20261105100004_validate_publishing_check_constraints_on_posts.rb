class ValidatePublishingCheckConstraintsOnPosts < ActiveRecord::Migration[8.1]
  # contract ของ check constraint: ตรวจแถวเดิม (ต้องรันหลัง backfill published_at แล้ว)
  def change
    validate_check_constraint :posts, name: "posts_status_valid"
    validate_check_constraint :posts, name: "posts_scheduled_requires_scheduled_at"
    validate_check_constraint :posts, name: "posts_published_requires_published_at"
  end
end
