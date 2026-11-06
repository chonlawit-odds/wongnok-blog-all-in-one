require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @category = categories(:one)
  end

  test "should get index" do
    get categories_url
    assert_response :success
  end

  test "index shows each category as a card with its post count" do
    get categories_url

    assert_select "#categories article", Category.count
    assert_select "##{ActionView::RecordIdentifier.dom_id(@category)}",
      text: /#{I18n.t("categories.posts_count", count: @category.posts.count)}/
  end

  test "index paginates 12 categories per page" do
    11.times { |i| Category.create!(name: "หมวด #{i}", slug: "extra-#{i}") } # รวม fixture 2 = 13 หมวด

    get categories_url
    assert_select "#categories article", 12
    assert_select "a[rel=next][href=?]", categories_path(page: 2)

    get categories_url(page: 2)
    assert_select "#categories article", 1
  end

  test "index shows empty state when there are no categories" do
    Post.destroy_all # ลบ comment/rich text ตาม dependent ก่อน ไม่ติด foreign key
    Category.delete_all

    get categories_url
    assert_select "#categories article", 0
    assert_select "#categories", text: /#{I18n.t("categories.empty.message")}/
  end

  test "should get new" do
    get new_category_url
    assert_response :success
  end

  test "should create category" do
    assert_difference("Category.count") do
      # slug ต้องไม่ซ้ำ (unique) จะใช้ค่าจาก fixture เหมือน scaffold เดิมไม่ได้
      post categories_url, params: { category: { name: "กีฬา", slug: "sports" } }
    end

    assert_redirected_to category_url(Category.last)
  end

  test "should show category" do
    get category_url(@category)
    assert_response :success
    assert_select "h1", @category.name
    assert_select "dd", I18n.t("categories.posts_count", count: @category.posts.count)
  end

  test "should get edit" do
    get edit_category_url(@category)
    assert_response :success
  end

  test "should update category" do
    patch category_url(@category), params: { category: { name: @category.name, slug: @category.slug } }
    assert_redirected_to category_url(@category)
  end

  test "should destroy category without posts" do
    empty_category = Category.create!(name: "ยังไม่มีบทความ", slug: "empty")

    assert_difference("Category.count", -1) do
      delete category_url(empty_category)
    end

    assert_redirected_to categories_url
  end

  test "should not destroy category that still has posts" do
    assert @category.posts.exists?

    assert_no_difference("Category.count") do
      delete category_url(@category)
    end

    assert_redirected_to categories_url
    follow_redirect!
    assert_select "[role=alert]", I18n.t("categories.destroy.failure")
  end
end
