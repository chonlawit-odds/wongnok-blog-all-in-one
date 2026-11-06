require "test_helper"

class Posts::PublicationsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include ActionMailer::TestHelper

  setup do
    @draft = Post.create!(title: "ฉบับร่าง", body: "<div>เนื้อหา</div>", category: categories(:one), user: users(:somchai))
    sign_in_as users(:somchai)
  end

  test "publish now schedules for now and enqueues PublishPostJob with the id only" do
    assert_enqueued_with(job: PublishPostJob, args: [ @draft.id ]) do
      post post_publication_url(@draft)
    end

    assert_redirected_to post_url(@draft)
    assert @draft.reload.scheduled?
  end

  test "the job waits in the queue until a worker runs it" do
    post post_publication_url(@draft)
    # ยังไม่มี worker มาหยิบ: งานรออยู่ในคิว โพสต์ยังไม่เผยแพร่ ยังไม่มีอีเมล
    assert @draft.reload.scheduled?
    assert_enqueued_jobs 1, only: PublishPostJob
    assert_no_enqueued_emails

    # worker กลับมา
    perform_enqueued_jobs only: PublishPostJob
    assert @draft.reload.published?
    assert_enqueued_emails Follower.count
  end

  test "another author cannot publish someone else's post (404, nothing queued)" do
    sign_in_as users(:malee)

    assert_no_enqueued_jobs only: PublishPostJob do
      assert_no_changes -> { @draft.reload.attributes } do
        post post_publication_url(@draft)
      end
    end

    assert_response :not_found
  end

  test "guest is sent to login, nothing is queued and the post is unchanged" do
    reset! # ทิ้ง session ที่ login ไว้ใน setup

    assert_no_enqueued_jobs only: PublishPostJob do
      assert_no_changes -> { @draft.reload.attributes } do
        post post_publication_url(@draft)
      end
    end

    assert_redirected_to new_session_url
  end

  test "admin can publish another author's draft, through the queue" do
    draft = posts(:post_draft)
    sign_in_as users(:boss)

    assert_enqueued_with(job: PublishPostJob, args: [ draft.id ]) do
      post post_publication_url(draft)
    end

    assert draft.reload.scheduled?, "request แค่ตั้งเวลาเป็นตอนนี้ แล้วให้ job เผยแพร่"
    assert_no_enqueued_emails
  end

  test "an already published post is not queued again" do
    assert_no_enqueued_jobs only: PublishPostJob do
      post post_publication_url(posts(:one))
    end

    assert_redirected_to post_url(posts(:one))
  end
end
