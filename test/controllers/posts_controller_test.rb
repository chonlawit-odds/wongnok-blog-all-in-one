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
    assert_select "#posts article", Post.published.count
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

  test "index shows cover thumbnail from a variant" do
    @post.update!(cover: fixture_file_upload("cover.png"))

    get posts_url
    assert_select "##{dom_id(@post)} figure img[src*=?]", "/rails/active_storage/representations/"
    assert_select "##{dom_id(posts(:two))} figure", false
  end

  test "index loads a page with at most 6 queries" do
    create_posts(11, with_cover: true)

    # count + COUNT/MAX ของ key กล่อง cache นอก + posts + categories + cover attachments + blobs
    # ไม่มี N+1 จำนวน comment มาจาก comments_count และไม่โหลด rich text (ข้อความย่อใช้ plain_text)
    # test ใช้ :null_store = cache miss ทุกครั้ง นี่จึงเป็นจำนวนตอน miss (ตอน hit ดู test/integration/posts_caching_test.rb)
    assert_queries_count(6) { get posts_url }
  end

  test "index lists only published posts, newest published first" do
    draft = create_post(title: "ฉบับร่าง")
    scheduled = create_post(title: "ตั้งเวลาไว้", status: :scheduled, scheduled_at: 1.hour.from_now)

    get posts_url
    assert_select "##{dom_id(draft)}", false
    assert_select "##{dom_id(scheduled)}", false
    assert_select "#posts article:first-child##{dom_id(posts(:one))}"
  end

  test "pending tab lists drafts and scheduled posts with their status" do
    draft = create_post(title: "ฉบับร่าง")
    scheduled = create_post(title: "ตั้งเวลาไว้", status: :scheduled, scheduled_at: 1.hour.from_now)

    get posts_url(view: "pending")
    assert_select "#posts article", 2
    assert_select "##{dom_id(draft)} .badge", text: "ฉบับร่าง"
    assert_select "##{dom_id(scheduled)} .badge", text: "ตั้งเวลาไว้"
    assert_select "##{dom_id(posts(:one))}", false
  end

  test "create a scheduled post" do
    sign_in_as users(:somchai)
    scheduled_at = 1.hour.from_now.change(sec: 0)

    assert_difference("Post.count") do
      post posts_url, params: { post: { category_id: @post.category_id, body: "<div>เนื้อหา</div>", title: "ตั้งเวลา",
                                        status: "scheduled", scheduled_at: scheduled_at.strftime("%Y-%m-%dT%H:%M") } }
    end

    created = Post.order(:id).last
    assert created.scheduled?
    assert_equal scheduled_at, created.scheduled_at
  end

  test "create rejects a schedule in the past" do
    sign_in_as users(:somchai)
    assert_no_difference("Post.count") do
      post posts_url, params: { post: { category_id: @post.category_id, body: "<div>เนื้อหา</div>", title: "ย้อนหลัง",
                                        status: "scheduled", scheduled_at: 1.day.ago.strftime("%Y-%m-%dT%H:%M") } }
    end

    assert_response :unprocessable_content
    assert_select "input.input-error[name='post[scheduled_at]']"
  end

  test "reschedule an existing scheduled post" do
    sign_in_as users(:somchai)
    scheduled = create_post(status: :scheduled, scheduled_at: 1.hour.from_now)
    new_time = 3.hours.from_now.change(sec: 0)

    patch post_url(scheduled), params: { post: { scheduled_at: new_time.strftime("%Y-%m-%dT%H:%M") } }

    assert_redirected_to post_url(scheduled)
    assert_equal new_time, scheduled.reload.scheduled_at
  end

  test "cannot publish directly through the form" do
    sign_in_as users(:somchai)
    draft = create_post

    patch post_url(draft), params: { post: { status: "published" } }

    assert_response :unprocessable_content
    assert draft.reload.draft?
  end

  test "show of a draft has the publish now button" do
    sign_in_as users(:somchai)
    draft = create_post

    get post_url(draft)
    assert_select "form[action=?] button", post_publication_path(draft)
  end

  test "show of a published post has no publish now button and its form hides the status" do
    sign_in_as users(:somchai)
    get post_url(@post)
    assert_select "form[action=?]", post_publication_path(@post), false

    get edit_post_url(@post)
    assert_select "input[name='post[status]']", false
  end

  test "show has breadcrumb back to index" do
    get post_url(@post)
    assert_select "nav.breadcrumbs a[href=?]", posts_path
    assert_select "h1", @post.title
  end

  test "user content is escaped" do
    xss_post = Post.create!(
      title: "<script>alert('xss')</script>",
      body: "<div><b>ตัวหนา</b><script>alert('body')</script><a href=\"javascript:alert(1)\" onclick=\"alert(2)\">ลิงก์</a></div>",
      category: categories(:one)
    )

    get post_url(xss_post)
    assert_not_includes response.body, "<script>alert("
    assert_includes response.body, "&lt;script&gt;"
    # body เป็น rich text: ตัวหนาได้ แต่ script / javascript: / onclick ต้องโดน sanitize ทิ้ง
    assert_select ".trix-content b", "ตัวหนา"
    assert_select ".trix-content a", "ลิงก์"
    assert_select ".trix-content a[href^='javascript']", false
    assert_select ".trix-content a[onclick]", false
  end

  test "show renders rich text body and cover" do
    @post.update!(body: "<div><strong>สำคัญ</strong> <a href=\"https://example.com\">อ่านต่อ</a></div>", cover: fixture_file_upload("cover.png"))

    get post_url(@post)
    assert_select ".trix-content strong", "สำคัญ"
    assert_select ".trix-content a[href='https://example.com']", "อ่านต่อ"
    assert_select "##{dom_id(@post)} figure img[src*=?]", "/rails/active_storage/representations/"
  end

  test "should get new" do
    sign_in_as users(:somchai)
    get new_post_url
    assert_response :success
    assert_select "trix-editor[input]"
    assert_select "input[type=file][name='post[cover]'][data-direct-upload-url]"
  end

  test "new shows category dropdown with prompt and all categories" do
    sign_in_as users(:somchai)
    get new_post_url
    assert_select "select[name='post[category_id]']" do
      assert_select "option[value='']", I18n.t("posts.form.category_prompt")
      assert_select "option[value='#{categories(:one).id}']", categories(:one).name
      assert_select "option[value='#{categories(:two).id}']", categories(:two).name
    end
  end

  test "edit preselects the current category" do
    sign_in_as users(:somchai)
    get edit_post_url(@post)
    assert_select "select[name='post[category_id]'] option[selected][value='#{@post.category_id}']"
  end

  test "create without a category re-renders form with dropdown in error state" do
    sign_in_as users(:somchai)
    assert_no_difference("Post.count") do
      post posts_url, params: { post: { category_id: "", body: "<div>เนื้อหา</div>", title: "ไม่มีหมวดหมู่" } }
    end

    assert_response :unprocessable_content
    assert_select "select.select-error[name='post[category_id]']"
  end

  test "should create post" do
    sign_in_as users(:somchai)
    assert_difference("Post.count") do
      post posts_url, params: { post: { category_id: @post.category_id, body: "<div><strong>เนื้อหา</strong></div>", title: @post.title } }
    end

    assert_redirected_to post_url(Post.last)
    assert_equal "เนื้อหา", Post.last.plain_text
    assert_equal users(:somchai), Post.last.user
  end

  test "create ignores user_id from params: the owner is always the signed-in user" do
    sign_in_as users(:somchai)

    post posts_url, params: { post: { category_id: @post.category_id, body: "<div>เนื้อหา</div>", title: "ปลอมเจ้าของ",
                                      user_id: users(:malee).id } }

    assert_equal users(:somchai), Post.order(:id).last.user
  end

  test "should create post with cover" do
    sign_in_as users(:somchai)
    assert_difference([ "Post.count", "ActiveStorage::Attachment.count" ]) do
      post posts_url, params: { post: { category_id: @post.category_id, body: "<div>เนื้อหา</div>", title: "มีรูปปก", cover: fixture_file_upload("cover.webp") } }
    end

    assert_equal "image/webp", Post.last.cover.content_type
  end

  test "create rejects a text file renamed to .png" do
    sign_in_as users(:somchai)
    assert_no_difference([ "Post.count", "ActiveStorage::Attachment.count" ]) do
      post posts_url, params: { post: { category_id: @post.category_id, body: "<div>เนื้อหา</div>", title: "รูปปลอม", cover: fixture_file_upload("not_an_image.png", "image/png") } }
    end

    assert_response :unprocessable_content
    assert_select "input[type=file].file-input-error"
  end

  test "should show post" do
    get post_url(@post)
    assert_response :success
  end

  test "should get edit" do
    sign_in_as users(:somchai)
    get edit_post_url(@post)
    assert_response :success
  end

  test "should update post" do
    sign_in_as users(:somchai)
    patch post_url(@post), params: { post: { category_id: @post.category_id, body: "<div>แก้แล้ว</div>", title: @post.title } }
    assert_redirected_to post_url(@post)
    assert_equal "แก้แล้ว", @post.reload.plain_text
  end

  test "update without choosing a new file keeps the existing cover" do
    sign_in_as users(:somchai)
    @post.update!(cover: fixture_file_upload("cover.png"))
    blob = @post.cover.blob

    patch post_url(@post), params: { post: { title: "แก้แค่หัวข้อ" } }
    assert_redirected_to post_url(@post)
    assert_equal blob, @post.reload.cover.blob
  end

  test "show has inline title frame, comments, counter and stream source" do
    sign_in_as users(:somchai)
    get post_url(@post)

    assert_select "turbo-frame##{dom_id(@post, :title)} h1", @post.title
    assert_select "turbo-frame##{dom_id(@post, :title)} a[href=?]", edit_post_path(@post)
    assert_select "turbo-cable-stream-source"
    assert_select "##{dom_id(@post, :comments_count)}", text: /#{@post.comments.count}/
    assert_select "##{dom_id(@post, :comments)} article", @post.comments.count
    assert_select "form##{dom_id(@post, :new_comment)} [data-controller=character-counter]"
  end

  test "edit from turbo-frame renders only the inline title form" do
    sign_in_as users(:somchai)
    get edit_post_url(@post), headers: { "Turbo-Frame" => dom_id(@post, :title) }

    assert_response :success
    assert_select "turbo-frame##{dom_id(@post, :title)} input[name='post[title]']"
    assert_select "trix-editor", false
    assert_select "header.navbar", false
  end

  test "edit opened directly renders the full page" do
    sign_in_as users(:somchai)
    get edit_post_url(@post)

    assert_response :success
    assert_select "header.navbar"
    assert_select "trix-editor[input]"
  end

  test "invalid inline title update re-renders frame with 422" do
    sign_in_as users(:somchai)
    patch post_url(@post), params: { post: { title: "" } }, headers: { "Turbo-Frame" => dom_id(@post, :title) }

    assert_response :unprocessable_content
    assert_select "turbo-frame##{dom_id(@post, :title)} input.input-error"
  end

  test "should destroy post" do
    sign_in_as users(:somchai)
    assert_difference("Post.count", -1) do
      delete post_url(@post)
    end

    assert_redirected_to posts_url
  end

  # --- สิทธิ์: อ่านได้ทุกคน  เขียนต้อง login  แก้/ลบได้เฉพาะเจ้าของหรือ admin (ไม่ใช่ = 404) ---

  test "guest is sent to login for writing actions and nothing changes" do
    get new_post_url
    assert_redirected_to new_session_url

    get edit_post_url(@post)
    assert_redirected_to new_session_url

    assert_no_difference("Post.count") do
      post posts_url, params: { post: { category_id: @post.category_id, body: "<div>เนื้อหา</div>", title: "แขก" } }
    end
    assert_redirected_to new_session_url

    patch post_url(@post), params: { post: { title: "แขกแก้" } }
    assert_redirected_to new_session_url
    assert_no_difference("Post.count") { delete post_url(@post) }
    assert_equal "MyString", @post.reload.title
  end

  test "another author gets 404 on edit, update and destroy, and the post stays the same" do
    sign_in_as users(:malee)

    get edit_post_url(@post)
    assert_response :not_found

    patch post_url(@post), params: { post: { title: "มาลีแก้ของสมชาย" } }
    assert_response :not_found
    assert_equal "MyString", @post.reload.title

    assert_no_difference("Post.count") { delete post_url(@post) }
    assert_response :not_found
  end

  test "admin can edit and update another author's post" do
    sign_in_as users(:boss)

    get edit_post_url(@post)
    assert_response :success

    patch post_url(@post), params: { post: { title: "บอสแก้ให้" } }
    assert_redirected_to post_url(@post)
    assert_equal "บอสแก้ให้", @post.reload.title
    assert_equal users(:somchai), @post.user, "admin แก้แล้วเจ้าของยังเป็นคนเดิม"
  end

  test "a post from before login existed (no owner) can be edited only by admin" do
    legacy = create_post(user: nil)

    sign_in_as users(:somchai)
    get edit_post_url(legacy)
    assert_response :not_found

    sign_in_as users(:boss)
    get edit_post_url(legacy)
    assert_response :success
  end

  test "show hides edit, destroy and publish buttons from guests and other authors" do
    draft = create_post

    get post_url(draft)
    assert_select "a[href=?]", edit_post_path(draft), false
    assert_select "form[action=?]", post_publication_path(draft), false
    assert_select "form[action=?] input[name=_method][value=delete]", post_path(draft), false

    sign_in_as users(:malee)
    get post_url(draft)
    assert_select "a[href=?]", edit_post_path(draft), false
    assert_select "form[action=?]", post_publication_path(draft), false
  end

  test "guest sees a login button instead of the comment form" do
    get post_url(@post)

    assert_select "form##{dom_id(@post, :new_comment)}", false
    assert_select "form[action='/auth/keycloak'][data-turbo=false] button"
  end

  private
    def create_post(user: users(:somchai), **attributes)
      Post.create!(title: "โพสต์ทดสอบ", body: "<div>เนื้อหาทดสอบ</div>", category: categories(:one), user:, **attributes)
    end

    # โพสต์ที่เผยแพร่แล้ว (หน้ารายการโชว์เฉพาะสถานะนี้)
    def create_posts(count, with_cover: false)
      count.times do |i|
        post = Post.new(title: "โพสต์ทดสอบ #{i}", body: "<div>เนื้อหาทดสอบ</div>", category: categories(i.even? ? :one : :two),
                        status: :published, published_at: Time.current)
        post.cover.attach(fixture_file_upload("cover.png")) if with_cover
        post.save!
      end
    end
end
