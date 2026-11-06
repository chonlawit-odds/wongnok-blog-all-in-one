require "test_helper"
require "turbo/broadcastable/test_helper"

class CommentTest < ActiveSupport::TestCase
  include ActionView::RecordIdentifier
  include ActiveJob::TestHelper
  # turbo-rails ใส่ helper นี้ให้ก็ต่อเมื่อ Action Cable โหลดแล้ว (on_load(:action_cable))
  # รัน test นี้เดี่ยว ๆ หรือเป็นตัวแรกของ worker จะไม่มี capture_turbo_stream_broadcasts จึง include เอง
  include Turbo::Broadcastable::TestHelper

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

  test "counter cache follows create and destroy" do
    comment = nil
    assert_difference -> { @post.reload.comments_count }, 1 do
      comment = @post.comments.create!(author_name: "ทดสอบ", body: "สวัสดี")
    end

    assert_difference -> { @post.reload.comments_count }, -1 do
      comment.destroy!
    end
  end

  test "creating or editing a comment touches the post (new cache key for its card)" do
    assert_changes -> { @post.reload.cache_version } do
      @post.comments.create!(author_name: "ทดสอบ", body: "สวัสดี")
    end

    assert_changes -> { @post.reload.cache_version } do
      comments(:one).update!(body: "แก้ความคิดเห็น")
    end
  end

  test "author_label reads both ways: the user's name first, author_name when there is no user yet" do
    assert_equal "Somchai Jaidee", comments(:one).author_label
    assert_equal "สมหญิง", comments(:two).author_label

    comment = @post.comments.build(author_name: "ยังไม่ backfill", body: "x")
    assert_equal "ยังไม่ backfill", comment.author_label
  end

  test "a new comment with a user also writes author_name (expand: both columns)" do
    comment = @post.comments.create!(user: users(:malee), body: "สวัสดี")

    assert_equal "Malee Sooksai", comment.author_name
  end

  test "author_name copied from a long user name still fits the column limit" do
    users(:malee).update!(name: "ม" * 80)
    comment = @post.comments.create!(user: users(:malee), body: "สวัสดี")

    assert_equal Comment::AUTHOR_NAME_MAX_LENGTH, comment.author_name.length
  end

  test "destroying broadcasts remove and an updated counter" do
    comment = comments(:one)

    streams = capture_turbo_stream_broadcasts(@post) do
      perform_enqueued_jobs { comment.destroy! }
    end

    actions = streams.to_h { |stream| [ stream["action"], stream["target"] ] }
    assert_equal dom_id(comment), actions["remove"]
    assert_equal dom_id(@post, :comments_count), actions["update"]
  end

  test "deleting a post deletes its comments" do
    assert_difference("Comment.count", -@post.comments.count) do
      @post.destroy!
    end
  end
end
