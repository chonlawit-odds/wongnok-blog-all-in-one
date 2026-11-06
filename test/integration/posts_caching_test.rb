require "test_helper"

# test ปกติใช้ :null_store (miss ทุกครั้ง) ไฟล์นี้สลับเป็น MemoryStore ชั่วคราว
# เพื่อตรวจว่าข้อมูลเปลี่ยนแล้ว cache key เปลี่ยนตามเอง โดยไม่มีโค้ดไหนลบ cache
class PostsCachingTest < ActionDispatch::IntegrationTest
  include ActionView::RecordIdentifier

  setup do
    @original_cache_store = ActionController::Base.cache_store
    ActionController::Base.cache_store = ActiveSupport::Cache::MemoryStore.new
    @post = posts(:one)
  end

  teardown do
    ActionController::Base.cache_store = @original_cache_store
  end

  test "second visit is served from cache without loading posts" do
    get posts_url

    # hit: เหลือแค่ COUNT ของ pagy + COUNT/MAX ของ key กล่องนอก ไม่ query โพสต์/หมวดหมู่/รูปปก
    # ทั้ง test อยู่ใน executor เดียว query cache ของ request แรกค้างมาถึง request นี้ (query ที่ซ้ำจะไม่ถูกนับ) จึงล้างก่อน
    ActiveRecord::Base.connection_pool.clear_query_cache
    assert_queries_count(2) { get posts_url }
    assert_select "##{dom_id(@post)} h2", @post.title
  end

  test "editing a title shows the new title" do
    get posts_url
    @post.update!(title: "หัวข้อใหม่")

    get posts_url
    assert_select "##{dom_id(@post)} h2", "หัวข้อใหม่"
  end

  test "a new comment re-renders only that card, other cards stay cached" do
    get posts_url
    @post.comments.create!(author_name: "ทดสอบ", body: "สวัสดี")

    written = fragments_written { get posts_url }

    assert_select "##{dom_id(@post)}", text: /3 ความคิดเห็น/
    # เขียนใหม่แค่กล่องนอก + การ์ดของโพสต์นี้  การ์ดของ posts(:two) ยัง hit
    assert_equal 2, written.size
    assert written.any? { |key| key.include?("/posts/#{@post.id}-") }
    assert written.none? { |key| key.include?("/posts/#{posts(:two).id}-") }
  end

  test "renaming a category refreshes the cards in it" do
    get posts_url
    categories(:one).update!(name: "หมวดใหม่")

    get posts_url
    assert_select "##{dom_id(@post)} .badge", "หมวดใหม่"
  end

  test "deleting a post shows the one that moves up from the next page" do
    # 10 โพสต์ใหม่ล้วนใหม่กว่า fixture: หน้าแรก = 10 ใบนี้  posts(:one) อยู่หน้า 2
    newest = 10.times.map do |i|
      Post.create!(title: "โพสต์ #{i}", body: "<div>เนื้อหา</div>", category: categories(:one),
                   status: :published, published_at: i.minutes.ago)
    end
    get posts_url
    assert_select "##{dom_id(@post)}", false

    # ลบใบที่ไม่ใช่ updated_at ล่าสุด: ถ้า key คิดจากหน้านี้อย่างเดียว (10 ใบ + updated_at ล่าสุด) จะได้ key เดิม
    newest.first.destroy!

    get posts_url
    assert_select "##{dom_id(newest.first)}", false
    assert_select "##{dom_id(@post)}"
    assert_select "#posts article", 10
  end

  private
    def fragments_written(&block)
      keys = []
      # key ใน log/event มี version ต่อท้าย เช่น views/posts/_post:digest/posts/1-20261106...
      callback = ->(event) { keys << ActiveSupport::Cache.expand_cache_key(event.payload[:key]) }
      ActiveSupport::Notifications.subscribed(callback, "write_fragment.action_controller", &block)
      keys
    end
end
