require "test_helper"

class CommentTest < ActiveSupport::TestCase
  include ActionView::RecordIdentifier
  include ActiveJob::TestHelper

  setup do
    @post = posts(:one)
  end

  test "requires author_name and body" do
    comment = @post.comments.build(author_name: "  ", body: "")

    assert_not comment.valid?
    assert comment.errors.added?(:author_name, :blank)
    assert comment.errors.added?(:body, :blank)
  end

  test "limits length" do
    comment = @post.comments.build(author_name: "ก" * 51, body: "ข" * 1_001)

    assert_not comment.valid?
    assert comment.errors.of_kind?(:author_name, :too_long)
    assert comment.errors.of_kind?(:body, :too_long)
  end

  test "normalizes whitespace and CRLF newlines" do
    comment = Comment.new(author_name: "  สมชาย   ใจดี ", body: " บรรทัดแรก\r\nบรรทัดสอง \n")

    assert_equal "สมชาย ใจดี", comment.author_name
    assert_equal "บรรทัดแรก\nบรรทัดสอง", comment.body
  end

  test "database enforces NOT NULL" do
    assert_raises(ActiveRecord::NotNullViolation) do
      Comment.insert!({ post_id: @post.id, author_name: nil, body: "x" })
    end
  end

  test "creating broadcasts append to the list and update to the counter" do
    streams = capture_turbo_stream_broadcasts(@post) do
      perform_enqueued_jobs do
        @post.comments.create!(author_name: "ทดสอบ", body: "สวัสดี")
      end
    end

    actions = streams.to_h { |stream| [ stream["action"], stream["target"] ] }
    assert_equal dom_id(@post, :comments), actions["append"]
    assert_equal dom_id(@post, :comments_count), actions["update"]
  end

  test "deleting a post deletes its comments" do
    assert_difference("Comment.count", -@post.comments.count) do
      @post.destroy!
    end
  end
end
