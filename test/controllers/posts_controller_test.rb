require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  include ActionView::RecordIdentifier

  setup do
    @post = posts(:one)
  end

  test "should get index" do
    get posts_url
    assert_response :success
  end

  test "index shows category name instead of category_id" do
    get posts_url
    assert_select "#posts article", Post.count
    assert_select "#posts .badge", text: categories(:one).name
  end

  test "index paginates 10 posts per page" do
    create_posts(11) # รวม fixture 2 = 13 โพสต์

    get posts_url
    assert_select "#posts article", 10
    assert_select "a[rel=next][href=?]", posts_path(page: 2)

    get posts_url(page: 2)
    assert_select "#posts article", 3
    assert_select "a[rel=prev][href=?]", posts_path(page: 1)
  end

  test "index loads a page with at most 3 queries" do
    create_posts(11)

    # count + posts + categories (includes) — ไม่มี N+1
    assert_queries_count(3) { get posts_url }
  end

  test "show has breadcrumb back to index" do
    get post_url(@post)
    assert_select "nav.breadcrumbs a[href=?]", posts_path
    assert_select "h1", @post.title
  end

  test "user content is escaped" do
    xss_post = Post.create!(title: "<script>alert('xss')</script>", description: "<b>ตัวหนา</b>", category: categories(:one))

    get post_url(xss_post)
    assert_not_includes response.body, "<script>alert("
    assert_not_includes response.body, "<b>ตัวหนา</b>"
    assert_includes response.body, "&lt;script&gt;"
  end

  test "should get new" do
    get new_post_url
    assert_response :success
  end

  test "should create post" do
    assert_difference("Post.count") do
      post posts_url, params: { post: { category_id: @post.category_id, description: @post.description, title: @post.title } }
    end

    assert_redirected_to post_url(Post.last)
  end

  test "should show post" do
    get post_url(@post)
    assert_response :success
  end

  test "should get edit" do
    get edit_post_url(@post)
    assert_response :success
  end

  test "should update post" do
    patch post_url(@post), params: { post: { category_id: @post.category_id, description: @post.description, title: @post.title } }
    assert_redirected_to post_url(@post)
  end

  test "show has inline title frame, comments, counter and stream source" do
    get post_url(@post)

    assert_select "turbo-frame##{dom_id(@post, :title)} h1", @post.title
    assert_select "turbo-frame##{dom_id(@post, :title)} a[href=?]", edit_post_path(@post)
    assert_select "turbo-cable-stream-source"
    assert_select "##{dom_id(@post, :comments_count)}", text: /#{@post.comments.count}/
    assert_select "##{dom_id(@post, :comments)} article", @post.comments.count
    assert_select "form##{dom_id(@post, :new_comment)} [data-controller=character-counter]"
  end

  test "edit from turbo-frame renders only the inline title form" do
    get edit_post_url(@post), headers: { "Turbo-Frame" => dom_id(@post, :title) }

    assert_response :success
    assert_select "turbo-frame##{dom_id(@post, :title)} input[name='post[title]']"
    assert_select "textarea[name='post[description]']", false
    assert_select "header.navbar", false
  end

  test "edit opened directly renders the full page" do
    get edit_post_url(@post)

    assert_response :success
    assert_select "header.navbar"
    assert_select "textarea[name='post[description]']"
  end

  test "invalid inline title update re-renders frame with 422" do
    patch post_url(@post), params: { post: { title: "" } }, headers: { "Turbo-Frame" => dom_id(@post, :title) }

    assert_response :unprocessable_content
    assert_select "turbo-frame##{dom_id(@post, :title)} input.input-error"
  end

  test "should destroy post" do
    assert_difference("Post.count", -1) do
      delete post_url(@post)
    end

    assert_redirected_to posts_url
  end

  private
    def create_posts(count)
      count.times do |i|
        Post.create!(title: "โพสต์ทดสอบ #{i}", description: "เนื้อหาทดสอบ", category: categories(i.even? ? :one : :two))
      end
    end
end
