require "test_helper"

class PublishDuePostsJobTest < ActiveJob::TestCase
  test "enqueues PublishPostJob with only the id of each due post" do
    due = create_post(status: :scheduled, scheduled_at: 1.minute.from_now)
    create_post(status: :scheduled, scheduled_at: 1.hour.from_now)
    create_post(status: :draft)

    travel 2.minutes do
      PublishDuePostsJob.perform_now
    end

    # ถึงเวลา = due กับ post_scheduled_overdue (fixture)  post_scheduled_tomorrow / ฉบับร่าง / ที่เผยแพร่แล้ว ไม่เข้าคิว
    assert_enqueued_jobs 2, only: PublishPostJob
    assert_enqueued_with job: PublishPostJob, args: [ due.id ]
    assert_enqueued_with job: PublishPostJob, args: [ posts(:post_scheduled_overdue).id ]
  end

  test "runs every minute in development and production" do
    config = ActiveSupport::ConfigurationFile.parse(Rails.root.join("config/recurring.yml"))

    %w[ development production ].each do |env|
      task = config.dig(env, "publish_due_posts")
      assert_equal "PublishDuePostsJob", task["class"]
      assert_equal "every minute", task["schedule"]
    end
  end

  private
    def create_post(**attributes)
      Post.create!(title: "ทดสอบ", body: "<div>เนื้อหา</div>", category: categories(:one), **attributes)
    end
end
