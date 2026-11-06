class CommentsController < ApplicationController
  before_action :require_login
  before_action :set_post

  # POST /posts/:post_id/comments
  # ผูก comment กับคนที่ login อยู่ (ชื่อผู้เขียนมาจากบัญชี ไม่ได้มาจากฟอร์ม)
  def create
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user

    respond_to do |format|
      if @comment.save
        format.turbo_stream # create.turbo_stream.erb
        format.html { redirect_to @post, notice: t(".success") }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace([ @post, :new_comment ], partial: "comments/form",
                                                    locals: { post: @post, comment: @comment, user: current_user }),
                 status: :unprocessable_content
        end
        format.html do
          @comments = @post.comments.includes(:user).chronological
          render "posts/show", status: :unprocessable_content
        end
      end
    end
  end

  # DELETE /posts/:post_id/comments/:id
  # หาจาก CommentPolicy.scope: ของตัวเอง (หรือทุกอันถ้าเป็น admin) ไม่ใช่ = RecordNotFound -> 404
  def destroy
    @comment = CommentPolicy.scope(current_user).where(post: @post).find(params.expect(:id))
    @comment.destroy!
    # counter_cache ลดตัวเลขที่ DB แล้ว แต่ @post ในหน่วยความจำยังเป็นค่าเก่า
    @post.reload

    respond_to do |format|
      format.turbo_stream # destroy.turbo_stream.erb
      format.html { redirect_to @post, notice: t(".success"), status: :see_other }
    end
  end

  private
    def set_post
      @post = Post.find(params.expect(:post_id))
    end

    # ไม่มี user_id / author_name: เจ้าของและชื่อมาจาก current_user เท่านั้น
    def comment_params
      params.expect(comment: [ :body ])
    end
end
