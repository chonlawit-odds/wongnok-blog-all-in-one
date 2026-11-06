class ValidatePostsUserForeignKey < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :posts, :users
  end
end
