# สิทธิ์ลบ comment: เจ้าของ หรือ admin เท่านั้น  หลักเดียวกับ PostPolicy
# controller หา comment จาก CommentPolicy.scope(current_user) ไม่ใช่ของตัวเอง = RecordNotFound -> 404
# comment เดิมก่อนมีระบบ login เป็นของ "ผู้ใช้เดิม" ที่ไม่มีบัญชี Keycloak จึงลบได้เฉพาะ admin
class CommentPolicy
  attr_reader :user, :comment

  def self.scope(user)
    if user.nil?
      Comment.none
    elsif user.admin?
      Comment.all
    else
      user.comments
    end
  end

  def initialize(user, comment)
    @user = user
    @comment = comment
  end

  def destroy?
    return false if user.nil?

    user.admin? || comment.user_id == user.id
  end
end
