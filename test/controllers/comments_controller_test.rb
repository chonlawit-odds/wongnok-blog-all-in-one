require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  include ActionView::RecordIdentifier

  setup do
    @post = posts(:one)
  end

  test "create via turbo stream appends, updates counter and resets form" do
    sign_in_as users(:malee)

    assert_difference("Comment.count") do
      post post_comments_url(@post), params: { comment: { body: "สวัสดีครับ" } }, as: :turbo_stream
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

  test "comment belongs to the signed-in user, name comes from the account not the form" do
    sign_in_as users(:malee)

    post post_comments_url(@post), params: { comment: { body: "สวัสดี", author_name: "ปลอมชื่อ", user_id: users(:boss).id } }

    comment = Comment.order(:id).last
    assert_equal users(:malee), comment.user
    assert_equal "Malee Sooksai", comment.author_name, "เขียนคู่กันช่วง expand: author_name = สำเนาชื่อ user"
    assert_equal "Malee Sooksai", comment.author_label
  end

  test "guest cannot comment" do
    assert_no_difference("Comment.count") do
      post post_comments_url(@post), params: { comment: { body: "แขก" } }
    end

    assert_redirected_to new_session_url
  end

  test "invalid create via turbo stream re-renders form with 422" do
    sign_in_as users(:malee)

    assert_no_difference("Comment.count") do
      post post_comments_url(@post), params: { comment: { body: "" } }, as: :turbo_stream
    end

    assert_turbo_stream action: :replace, target: dom_id(@post, :new_comment), status: :unprocessable_content do
      assert_select "[role=alert]"
    end
  end

  test "create via html redirects to post" do
    sign_in_as users(:malee)

    post post_comments_url(@post), params: { comment: { body: "สวัสดี" } }

    assert_redirected_to post_url(@post)
  end

  test "invalid create via html re-renders post page with 422" do
    sign_in_as users(:malee)

    post post_comments_url(@post), params: { comment: { body: "" } }

    assert_response :unprocessable_content
    assert_select "form##{dom_id(@post, :new_comment)} [role=alert]"
  end

  test "owner deletes own comment, list and counter update" do
    sign_in_as users(:somchai)

    assert_difference -> { @post.reload.comments_count }, -1 do
      delete post_comment_url(@post, comments(:one)), as: :turbo_stream
    end

    assert_turbo_stream action: :remove, target: dom_id(comments(:one))
    assert_turbo_stream action: :update, target: dom_id(@post, :comments_count) do
      assert_select "template", text: /1/
    end
  end

  test "another user gets 404 when deleting a comment that is not theirs" do
    sign_in_as users(:malee)

    assert_no_difference("Comment.count") do
      delete post_comment_url(@post, comments(:one))
    end

    assert_response :not_found
  end

  test "admin can delete anyone's comment, including old ones from before login existed" do
    sign_in_as users(:boss)

    assert_difference("Comment.count", -1) do
      delete post_comment_url(@post, comments(:two))
    end

    assert_redirected_to post_url(@post)
  end

  test "a comment can only be deleted through the post it belongs to" do
    sign_in_as users(:boss)

    delete post_comment_url(posts(:two), comments(:one))

    assert_response :not_found
  end

  test "post page shows the delete button only on comments the viewer may delete" do
    sign_in_as users(:somchai)
    get post_url(@post)

    assert_select "##{dom_id(comments(:one))} form[action=?]", post_comment_path(@post, comments(:one))
    assert_select "##{dom_id(comments(:two))} form", false
    # comment เดิมก่อนมีระบบ login ยังโชว์ชื่อเดิม
    assert_select "##{dom_id(comments(:two))}", text: /สมหญิง/
  end
end
