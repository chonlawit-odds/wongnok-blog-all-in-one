require "test_helper"

class PublishPostJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  # จำลอง DB deadlock ทุกครั้งที่รัน เพื่อดูการ retry
  class DeadlockingJob < PublishPostJob
    def perform(*)
      raise ActiveRecord::Deadlocked, "deadlock detected"
    end
  end

  setup do
    @post = Post.create!(title: "ตั้งเวลาไว้", body: "<div>เนื้อหา</div>", category: categories(:one),
                         status: :scheduled, scheduled_at: 1.minute.from_now)
  end

  test "publishes a due post and enqueues one email per follower with ids only" do
    travel 2.minutes do
      assert_enqueued_emails Follower.count do
        PublishPostJob.perform_now(@post.id)
      end
    end

    assert @post.reload.published?
    assert_not_nil @post.published_at
    assert_equal Follower.count, @post.post_notifications.count
    assert_enqueued_email_with PostMailer, :published, params: { post_id: @post.id, follower_id: followers(:ann).id }
  end

  test "running again 3 times keeps the status and sends no extra email" do
    travel 2.minutes do
      PublishPostJob.perform_now(@post.id)
      published_at = @post.reload.published_at

      assert_no_enqueued_emails do
        3.times { PublishPostJob.perform_now(@post.id) }
      end
      assert @post.reload.published?
      assert_equal published_at, @post.published_at
      assert_equal Follower.count, @post.post_notifications.count
    end
  end

  test "perform_now 3 times sends exactly one email" do
    post = posts(:post_scheduled_overdue)
    Follower.where.not(id: followers(:ann).id).delete_all # สถานการณ์: มีผู้ติดตามคนเดียว

    # assert_emails แบบ block ส่งอีเมลที่เข้าคิว (deliver_later) ระหว่าง block จริง แล้วนับที่ส่งออกไป
    assert_emails 1 do
      3.times { PublishPostJob.perform_now(post.id) }
    end

    assert post.reload.published?
    mail = ActionMailer::Base.deliveries.last
    assert_equal [ followers(:ann).email ], mail.to
    assert_includes mail.subject, post.title
  end

  test "a post scheduled for tomorrow: 3 runs publish nothing and send nothing" do
    post = posts(:post_scheduled_tomorrow)

    assert_no_emails do
      3.times { PublishPostJob.perform_now(post.id) }
    end

    assert post.reload.scheduled?
    assert_nil post.published_at
    assert_empty post.post_notifications
  end

  test "does not publish before the scheduled time" do
    assert_no_enqueued_emails { PublishPostJob.perform_now(@post.id) }
    assert @post.reload.scheduled?
  end

  test "follows the new time after the user reschedules" do
    @post.update!(scheduled_at: 10.minutes.from_now)

    # job ที่เข้าคิวตามเวลาเดิม: ถึงเวลาเดิมแล้วแต่ยังไม่ถึงเวลาใหม่ -> ไม่ทำอะไร
    travel(2.minutes) { PublishPostJob.perform_now(@post.id) }
    assert @post.reload.scheduled?

    travel(11.minutes) { PublishPostJob.perform_now(@post.id) }
    assert @post.reload.published?
  end

  test "does not publish a draft" do
    @post.update!(status: :draft)

    travel 2.minutes do
      assert_no_enqueued_emails { PublishPostJob.perform_now(@post.id) }
    end
    assert @post.reload.draft?
  end

  test "skips followers already claimed by another worker" do
    travel 2.minutes do
      # worker อีกตัวใส่แถวของ ann ไปก่อนแล้ว: unique index ทำให้รอบนี้ไม่ได้แถวนั้นคืนมา
      PostNotification.create!(post: @post, follower: followers(:ann))

      assert_enqueued_emails Follower.count - 1 do
        PublishPostJob.perform_now(@post.id)
      end
    end
    assert_enqueued_email_with PostMailer, :published, params: { post_id: @post.id, follower_id: followers(:bob).id }
    assert_equal Follower.count, @post.post_notifications.count
  end

  test "a rerun does not email people who followed after publishing" do
    travel(2.minutes) { PublishPostJob.perform_now(@post.id) }

    travel 1.hour do
      Follower.create!(email: "late@example.com")
      assert_no_enqueued_emails { PublishPostJob.perform_now(@post.id) }
    end
  end

  test "is discarded when the post was deleted" do
    @post.destroy!

    assert_nothing_raised { PublishPostJob.perform_now(@post.id) }
    assert_no_enqueued_jobs
  end

  test "retries DB deadlocks with a growing wait, up to 5 attempts" do
    freeze_time do
      job = DeadlockingJob.new(@post.id)

      waits = 4.times.map do
        job.perform_now
        enqueued_jobs.last.fetch(:at) - Time.current.to_f
      end
      assert_equal waits.sort, waits
      assert_operator waits.last, :>, waits.first * 10

      # ครั้งที่ 5 หมดโควตา: โยน error ออกไปให้ Solid Queue เก็บเป็น failed execution
      assert_raises(ActiveRecord::Deadlocked) { job.perform_now }
    end
  end
end
