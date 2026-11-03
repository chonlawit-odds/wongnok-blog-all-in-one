require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  include ActionView::RecordIdentifier

  setup do
    @post = posts(:one)
  end

  test "create via turbo stream appends, updates counter and resets form" do
    assert_difference("Comment.count") do
      post post_comments_url(@post), params: { comment: { author_name: "ทดสอบ", body: "สวัสดีครับ" } }, as: :turbo_stream
    end

    assert_response :success
    assert_turbo_stream action: :append, target: dom_id(@post, :comments) do
      assert_select "article", text: /สวัสดีครับ/
    end
    assert_turbo_stream action: :update, target: dom_id(@post, :comments_count) do
      assert_select "template", text: /#{@post.comments.count}/
    end
    assert_turbo_stream action: :replace, target: dom_id(@post, :new_comment) do
      assert_select "textarea[name='comment[body]']", text: ""
    end
  end

  test "invalid create via turbo stream re-renders form with 422" do
    assert_no_difference("Comment.count") do
      post post_comments_url(@post), params: { comment: { author_name: "", body: "" } }, as: :turbo_stream
    end

    assert_turbo_stream action: :replace, target: dom_id(@post, :new_comment), status: :unprocessable_content do
      assert_select "[role=alert]"
    end
  end

  test "create via html redirects to post" do
    post post_comments_url(@post), params: { comment: { author_name: "ทดสอบ", body: "สวัสดี" } }

    assert_redirected_to post_url(@post)
  end

  test "invalid create via html re-renders post page with 422" do
    post post_comments_url(@post), params: { comment: { author_name: "", body: "" } }

    assert_response :unprocessable_content
    assert_select "form##{dom_id(@post, :new_comment)} [role=alert]"
  end
end
