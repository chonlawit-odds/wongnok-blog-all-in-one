class PostsController < ApplicationController
  before_action :set_post, only: %i[ show edit update destroy ]
  before_action :set_turbo_frame_variant, only: %i[ edit update ]
  before_action :set_categories, only: %i[ new edit create update ]

  # GET /posts or /posts.json
  # ข้อความย่อใช้คอลัมน์ plain_text จึงไม่ต้องโหลด rich text ของทุกโพสต์มาที่หน้านี้
  # ปกติโชว์เฉพาะที่เผยแพร่แล้ว  ?view=pending = ฉบับร่าง + ที่ตั้งเวลาไว้ (ไว้ให้ผู้เขียนกลับไปแก้)
  def index
    @pending = params[:view] == "pending"
    posts = @pending ? Post.not_published.recent : Post.latest_published
    @pagy, @posts = pagy(posts.includes(:category).with_attached_cover, limit: 10)
    @follower = Follower.new
  end

  # GET /posts/1 or /posts/1.json
  def show
    @comments = @post.comments.chronological
    @comment = Comment.new
  end

  # GET /posts/new
  def new
    @post = Post.new
  end

  # GET /posts/1/edit
  def edit
  end

  # POST /posts or /posts.json
  def create
    @post = Post.new(post_params)

    respond_to do |format|
      if @post.save
        format.html { redirect_to @post, notice: "Post was successfully created." }
        format.json { render :show, status: :created, location: @post }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @post.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /posts/1 or /posts/1.json
  def update
    respond_to do |format|
      if @post.update(post_params)
        format.html { redirect_to @post, notice: "Post was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @post }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @post.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /posts/1 or /posts/1.json
  def destroy
    @post.destroy!

    respond_to do |format|
      format.html { redirect_to posts_path, notice: "Post was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = Post.with_rich_text_body.with_attached_cover.find(params.expect(:id))
    end

    # แก้หัวข้อแบบ inline จาก turbo-frame ในหน้า show -> edit.html+turbo_frame.erb (ฟอร์มเฉพาะหัวข้อ)
    # เปิด /posts/:id/edit ตรง ๆ ไม่มี header Turbo-Frame -> edit.html.erb หน้าเต็มเหมือนเดิม
    def set_turbo_frame_variant
      request.variant = :turbo_frame if turbo_frame_request?
    end

    # ตัวเลือกใน dropdown หมวดหมู่ของฟอร์ม เป็น relation แบบ lazy จะ query เฉพาะตอน render ฟอร์มเต็มจริง
    # (create/update ที่ redirect หรือฟอร์มแก้หัวข้อแบบ inline ไม่ได้ใช้ จึงไม่เสีย query)
    def set_categories
      @categories = Category.alphabetical
    end

    # Only allow a list of trusted parameters through.
    # status รับได้แค่ draft/scheduled ในทางปฏิบัติ: ไม่รับ published_at จากฟอร์ม
    # ส่ง status=published มาเองจะติด validation (published_at ว่าง) ต้องผ่าน PublishPostJob เท่านั้น
    def post_params
      params.expect(post: [ :title, :body, :cover, :category_id, :status, :scheduled_at ])
    end
end
