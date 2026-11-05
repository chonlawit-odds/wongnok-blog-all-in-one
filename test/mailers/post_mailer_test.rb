require "test_helper"

class PostMailerTest < ActionMailer::TestCase
  test "published tells the follower about the new post" do
    post = posts(:one)
    follower = followers(:ann)

    mail = PostMailer.with(post_id: post.id, follower_id: follower.id).published

    assert_equal [ follower.email ], mail.to
    assert_equal "บทความใหม่: #{post.title}", mail.subject
    assert_includes mail.text_part.body.to_s, "http://example.com/posts/#{post.id}"
    assert_includes mail.html_part.body.to_s, "http://example.com/posts/#{post.id}"
  end

  test "sends nothing when the post or follower is gone" do
    assert_no_emails do
      PostMailer.with(post_id: 0, follower_id: followers(:ann).id).published.deliver_now
      PostMailer.with(post_id: posts(:one).id, follower_id: 0).published.deliver_now
    end
  end

  test "sends nothing for a post that is not published" do
    posts(:one).update!(status: :draft)

    assert_no_emails do
      PostMailer.with(post_id: posts(:one).id, follower_id: followers(:ann).id).published.deliver_now
    end
  end
end
