require "application_system_test_case"

class PostsTest < ApplicationSystemTestCase
  include ActionView::RecordIdentifier

  test "the owner edits the title inline and the rest of the page is left alone" do
    post = posts(:post_published_last_week)
    sign_in_as users(:somchai)
    visit post_path(post)

    # พิมพ์ comment ค้างไว้: ถ้าทั้งหน้าโหลดใหม่ ข้อความนี้จะหาย  ถ้าเปลี่ยนแค่ frame หัวข้อ ข้อความยังอยู่
    fill_in "comment[body]", with: "ยังพิมพ์ไม่เสร็จ"

    within "turbo-frame##{dom_id(post, :title)}" do
      click_on I18n.t("posts.show.edit_title")
      fill_in "post[title]", with: "หัวข้อใหม่แบบ inline"
      click_on I18n.t("posts.edit.save")

      assert_selector "h1", text: "หัวข้อใหม่แบบ inline"
      assert_no_field "post[title]"
    end

    assert_field "comment[body]", with: "ยังพิมพ์ไม่เสร็จ"
    assert_equal "หัวข้อใหม่แบบ inline", post.reload.title
  end
end
