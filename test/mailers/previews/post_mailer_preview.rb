# ดูหน้าตาอีเมลได้ที่ http://localhost:3000/rails/mailers/post_mailer/published
# (ต้องมีโพสต์ที่เผยแพร่แล้วและผู้ติดตามอย่างน้อยอย่างละหนึ่งใน DB)
class PostMailerPreview < ActionMailer::Preview
  def published
    PostMailer.with(post_id: Post.published.pick(:id), follower_id: Follower.pick(:id)).published
  end
end
