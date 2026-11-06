require "test_helper"

class PostsHelperTest < ActionView::TestCase
  test "reading_minutes rounds up and is at least 1 minute" do
    assert_equal 1, reading_minutes(Post.new(plain_text: ""))
    assert_equal 1, reading_minutes(Post.new(plain_text: "ก" * 1_000))
    assert_equal 2, reading_minutes(Post.new(plain_text: "ก" * 1_001))
  end
end
