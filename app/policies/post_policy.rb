# สิทธิ์แก้ / ลบ / เผยแพร่โพสต์: เจ้าของ หรือ admin เท่านั้น  (อ่านได้ทุกคน ไม่ต้องผ่านคลาสนี้)
#
# ด่านจริงอยู่ที่ controller: หาโพสต์จาก PostPolicy.scope(current_user) ไม่ใช่ Post.find แล้วค่อยเช็ก
#   author = current_user.posts  admin = ทุกโพสต์  ไม่ใช่ของตัวเอง = ActiveRecord::RecordNotFound -> 404
#   ตอบ 404 ไม่ใช่ 403: คนที่ไม่มีสิทธิ์ไม่ควรรู้ด้วยซ้ำว่ามีโพสต์ id นี้อยู่
# view ใช้ update? แค่ซ่อนปุ่ม (ซ่อนปุ่มไม่ใช่ด่าน ยิง request ตรง ๆ ก็ยังต้องโดน scope กันอยู่ดี)
# scope กับ update? ต้องใช้กฎเดียวกันเสมอ (test/policies/post_policy_test.rb ตรวจทั้งคู่)
class PostPolicy
  attr_reader :user, :post

  def self.scope(user)
    if user.nil?
      Post.none
    elsif user.admin?
      Post.all
    else
      user.posts
    end
  end

  def initialize(user, post)
    @user = user
    @post = post
  end

  def update?
    return false if user.nil?

    user.admin? || post.user_id == user.id
  end

  def destroy? = update?
  def publish? = update?
end
