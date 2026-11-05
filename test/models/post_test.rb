require "test_helper"

class PostTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile

  test "requires body" do
    post = build_post(body: "")

    assert_not post.valid?
    assert post.errors.added?(:body, :blank)
  end

  test "saving body fills plain_text and keeps description in sync (expand-contract)" do
    post = build_post(body: "<div><strong>ตัวหนา</strong> และ <a href=\"https://example.com\">ลิงก์</a></div>")
    post.save!

    assert_equal "ตัวหนา และ ลิงก์", post.plain_text
    assert_equal post.plain_text, post.description
  end

  test "updating only the title keeps plain_text" do
    post = posts(:one)
    post.update!(title: "หัวข้อใหม่")

    assert_equal "MyText", post.reload.plain_text
  end

  %w[ cover.png cover.jpg cover.webp ].each do |filename|
    test "accepts #{filename} as cover" do
      post = build_post
      post.cover.attach(fixture_file_upload(filename))

      assert post.valid?, post.errors.full_messages.to_sentence
    end
  end

  test "rejects a text file renamed to .png even when client says image/png" do
    post = build_post
    post.cover.attach(fixture_file_upload("not_an_image.png", "image/png"))

    assert_not post.valid?
    assert post.errors.added?(:cover, :invalid_image_type)
  end

  test "rejects a text file renamed to .png that was direct-uploaded" do
    # จำลอง direct upload: blob อยู่บน storage แล้ว ฟอร์มส่งมาแค่ signed_id
    blob = ActiveStorage::Blob.create_and_upload!(
      io: file_fixture("not_an_image.png").open, filename: "not_an_image.png", content_type: "image/png", identify: false
    )
    post = build_post(cover: blob.signed_id)

    assert_not post.valid?
    assert post.errors.added?(:cover, :invalid_image_type)
  end

  test "accepts a direct-uploaded png" do
    blob = ActiveStorage::Blob.create_and_upload!(io: file_fixture("cover.png").open, filename: "cover.png")
    post = build_post(cover: blob.signed_id)

    assert post.valid?, post.errors.full_messages.to_sentence
  end

  test "rejects cover larger than 5MB" do
    png_header = file_fixture("cover.png").binread
    big = StringIO.new(png_header + ("\0" * Post::COVER_MAX_SIZE))
    post = build_post
    post.cover.attach(io: big, filename: "big.png", content_type: "image/png")

    assert_not post.valid?
    assert post.errors.added?(:cover, :file_too_large, size: "5 เมกะไบต์")
  end

  test "new post starts as draft" do
    assert build_post.draft?
  end

  test "scheduled post requires scheduled_at" do
    post = build_post(status: :scheduled)

    assert_not post.valid?
    assert post.errors.added?(:scheduled_at, :blank)
  end

  test "cannot schedule in the past but can pick the current minute" do
    freeze_time do
      assert_not build_post(status: :scheduled, scheduled_at: 1.minute.ago.beginning_of_minute).valid?
      assert build_post(status: :scheduled, scheduled_at: Time.current.beginning_of_minute).valid?
    end
  end

  test "cannot become published without published_at (only publish_if_due! publishes)" do
    post = posts(:one)
    post.update_columns(status: "draft", published_at: nil)

    assert_not post.update(status: :published)
    assert post.errors.added?(:published_at, :blank)
  end

  test "unknown status is a validation error, not an exception" do
    post = build_post(status: "archived")

    assert_not post.valid?
    assert post.errors.added?(:status, :inclusion, value: "archived")
  end

  test "publish_if_due! only publishes a scheduled post whose time has come, once" do
    post = build_post(status: :scheduled, scheduled_at: 5.minutes.from_now)
    post.save!

    assert_not post.publish_if_due!
    assert post.reload.scheduled?

    # travel ตัดเศษ microsecond ทิ้ง จึงเผื่อเกินเวลาที่ตั้งไว้ไป 1 นาที
    travel 6.minutes do
      assert post.publish_if_due!
      assert post.reload.published?
      assert_equal Time.current, post.published_at

      assert_not post.publish_if_due!, "รอบที่สองต้องไม่เปลี่ยนอะไร"
    end
  end

  test "publish_if_due! leaves drafts alone" do
    post = build_post
    post.save!

    assert_not post.publish_if_due!
    assert post.reload.draft?
  end

  test "due_for_publishing finds only scheduled posts whose time has passed" do
    due = build_post(status: :scheduled, scheduled_at: 1.minute.from_now).tap(&:save!)
    later = build_post(status: :scheduled, scheduled_at: 1.hour.from_now).tap(&:save!)

    travel 2.minutes do
      assert_includes Post.due_for_publishing, due
      assert_not_includes Post.due_for_publishing, later
      assert_not_includes Post.due_for_publishing, posts(:one)
    end
  end

  test "check constraint rejects scheduled without scheduled_at at the DB level" do
    assert_raises(ActiveRecord::StatementInvalid) do
      posts(:one).update_columns(status: "scheduled", scheduled_at: nil)
    end
  end

  private
    def build_post(**attributes)
      Post.new(title: "ทดสอบ", body: "<div>เนื้อหา</div>", category: categories(:one), **attributes)
    end
end
