class PostMailer < ApplicationMailer
  # params มีแค่ id (post_id, follower_id) โหลดสดตอนส่งจริง: หัวข้อ/อีเมลเป็นค่าล่าสุดเสมอ
  # ลิงก์ทั้งหมดสร้างที่นี่ตอนส่ง ไม่รับ URL หรือ token ที่สร้างไว้ล่วงหน้าผ่าน job (อาจหมดอายุระหว่างรอคิว)
  def published
    @post = Post.published.find_by(id: params[:post_id])
    @follower = Follower.find_by(id: params[:follower_id])
    # โพสต์ถูกลบ/คนติดตามถูกลบระหว่างรอคิว: ไม่เรียก mail = ActionMailer ไม่ส่ง และไม่ error
    return if @post.nil? || @follower.nil?

    mail to: @follower.email, subject: t(".subject", title: @post.title)
  end
end
