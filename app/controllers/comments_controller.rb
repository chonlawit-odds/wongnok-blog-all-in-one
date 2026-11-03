class CommentsController < ApplicationController
  before_action :set_post

  # POST /posts/:post_id/comments
  def create
    @comment = @post.comments.build(comment_params)

    respond_to do |format|
      if @comment.save
        format.turbo_stream # create.turbo_stream.erb
        format.html { redirect_to @post, notice: t(".success") }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace([ @post, :new_comment ], partial: "comments/form",
                                                    locals: { post: @post, comment: @comment }),
                 status: :unprocessable_content
        end
        format.html do
          @comments = @post.comments.chronological
          render "posts/show", status: :unprocessable_content
        end
      end
    end
  end

  private
    def set_post
      @post = Post.find(params.expect(:post_id))
    end

    def comment_params
      params.expect(comment: [ :author_name, :body ])
    end
end
