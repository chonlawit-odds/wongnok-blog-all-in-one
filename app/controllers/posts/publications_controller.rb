class Posts::PublicationsController < ApplicationController
  before_action :require_login
  before_action :set_post

  # POST /posts/:post_id/publication
  # "เผยแพร่ทันที" = ตั้งเวลาเป็นตอนนี้แล้วเข้าคิว PublishPostJob
  # ให้ job เป็นทางเดียวที่โพสต์กลายเป็น published และแจ้งผู้ติดตาม (ไม่ส่งอีเมลใน request หรือ callback ของ model)
  # bin/jobs ปิดอยู่: งานรอใน solid_queue_ready_executions ไม่หาย เปิดกลับมาเมื่อไรก็ถูกทำ
  def create
    if @post.published?
      redirect_to @post, notice: t(".already_published"), status: :see_other
    else
      # update! commit เสร็จก่อนแล้วค่อยเข้าคิว: job เห็นค่าที่บันทึกแล้วแน่นอน
      @post.update!(status: :scheduled, scheduled_at: Time.current)
      PublishPostJob.perform_later(@post.id)
      redirect_to @post, notice: t(".success"), status: :see_other
    end
  end

  private
    # เผยแพร่ = แก้โพสต์: เจ้าของหรือ admin เท่านั้น ไม่ใช่ของตัวเอง = 404
    def set_post
      @post = PostPolicy.scope(current_user).find(params.expect(:post_id))
    end
end
