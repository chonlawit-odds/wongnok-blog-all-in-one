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

  private
    def build_post(**attributes)
      Post.new(title: "ทดสอบ", body: "<div>เนื้อหา</div>", category: categories(:one), **attributes)
    end
end
