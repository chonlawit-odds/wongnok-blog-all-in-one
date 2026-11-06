require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "renaming touches its posts so their cached cards get a new key" do
    category = categories(:one)
    post = posts(:one)

    assert_changes -> { post.reload.cache_version } do
      category.update!(name: "ชื่อใหม่")
    end
  end

  test "saving without renaming does not touch posts" do
    post = posts(:one)

    assert_no_changes -> { post.reload.cache_version } do
      categories(:one).update!(slug: "new-slug")
    end
  end
end
