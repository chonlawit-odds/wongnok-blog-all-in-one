require "application_system_test_case"

class CommentsTest < ApplicationSystemTestCase
  include ActionView::RecordIdentifier

  test "a new comment shows up live in another reader's open tab" do
    post = posts(:post_published_last_week)

    # ผู้อ่านคนแรกเปิดหน้าโพสต์ค้างไว้ รอจนต่อ Action Cable ติด (Turbo ใส่ attribute connected ให้)
    visit post_path(post)
    assert_selector "turbo-cable-stream-source[connected]", visible: :all

    using_session(:malee) do
      sign_in_as users(:malee)
      visit post_path(post)

      perform_enqueued_jobs do
        fill_in "comment[body]", with: "ลองทำตามแล้ว อร่อยมากค่ะ"
        click_on I18n.t("comments.form.submit")
        within("##{dom_id(post, :comments)}") { assert_text "ลองทำตามแล้ว อร่อยมากค่ะ" }
      end
    end

    # แท็บแรกไม่ได้ reload: comment กับตัวนับมาเองทาง broadcast
    within("##{dom_id(post, :comments)}") { assert_text "ลองทำตามแล้ว อร่อยมากค่ะ" }
    assert_selector "##{dom_id(post, :comments_count)}", text: I18n.t("comments.count.title", count: 3)
  end
end
