class PostsController < ApplicationController
  # อ่านได้ทุกคน  เขียน/แก้/ลบ ต้อง login (ก่อน set_editable_post: ยังไม่ login = ไปหน้า login ไม่ใช่ 404)
  before_action :require_login, except: %i[ index show ]
  before_action :set_post, only: :show
  before_action :set_editable_post, only: %i[ edit update destroy ]
  before_action :set_turbo_frame_variant, only: %i[ edit update ]
  before_action :set_categories, only: %i[ new edit create update ]

  # GET /posts or /posts.json
  # ข้อความย่อใช้คอลัมน์ plain_text จึงไม่ต้องโหลด rich text ของทุกโพสต์มาที่หน้านี้
  # ปกติโชว์เฉพาะที่เผยแพร่แล้ว  ?view=pending = ฉบับร่าง + ที่ตั้งเวลาไว้ (ไว้ให้ผู้เขียนกลับไปแก้)
  # @posts_scope = ทั้งรายการก่อนแบ่งหน้า ใช้เป็น key ของ cache ชั้นนอกใน index.html.erb
  def index
    @pending = params[:view] == "pending"
    @posts_scope = @pending ? Post.not_published.recent : Post.latest_published
    @pagy, @posts = pagy(@posts_scope.includes(:category).with_attached_cover, limit: 10)
    @follower = Follower.new
  end

  # GET /posts/1 or /posts/1.json
  def show
    @comments = @post.comments.includes(:user).chronological
    @comment = Comment.new
  end

  # GET /posts/new
  def new
    @post = current_user.posts.build
  end

  # GET /posts/1/edit
  def edit
  end

  # POST /posts or /posts.json
  # เจ้าของ = คนที่ login อยู่เสมอ (user_id ไม่อยู่ใน post_params ส่งมาก็ไม่รับ)
  def create
    @post = current_user.posts.build(post_params)

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

    # แก้/ลบได้เฉพาะโพสต์ใน PostPolicy.scope: author = current_user.posts  admin = ทุกโพสต์
    # ไม่ใช่ของตัวเอง = RecordNotFound -> 404 (ไม่ใช่ 403)  ก่อน update/destroy จึงไม่มีทางแตะโพสต์คนอื่น
    def set_editable_post
      @post = PostPolicy.scope(current_user).with_rich_text_body.with_attached_cover.find(params.expect(:id))
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
