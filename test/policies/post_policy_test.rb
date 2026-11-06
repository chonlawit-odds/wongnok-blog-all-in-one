require "test_helper"

class PostPolicyTest < ActiveSupport::TestCase
  setup do
    @post = posts(:one) # ของ somchai
  end

  test "owner and admin may update, other authors and guests may not" do
    assert PostPolicy.new(users(:somchai), @post).update?
    assert PostPolicy.new(users(:boss), @post).update?
    assert_not PostPolicy.new(users(:malee), @post).update?
    assert_not PostPolicy.new(nil, @post).update?
  end

  test "a post without an owner is admin only" do
    @post.user = nil

    assert PostPolicy.new(users(:boss), @post).update?
    assert_not PostPolicy.new(users(:somchai), @post).update?
  end

  test "scope follows the same rule as update?" do
    assert_equal posts(:one, :post_draft, :post_scheduled_tomorrow, :post_scheduled_overdue, :post_published_last_week).sort_by(&:id),
                 PostPolicy.scope(users(:somchai)).order(:id).to_a
    assert_equal [ posts(:two) ], PostPolicy.scope(users(:malee)).to_a
    assert_equal Post.count, PostPolicy.scope(users(:boss)).count
    assert_empty PostPolicy.scope(nil)

    Post.find_each do |post|
      users(:somchai, :malee, :boss).each do |user|
        assert_equal PostPolicy.new(user, post).update?, PostPolicy.scope(user).exists?(post.id), "#{user.name} / post #{post.id}"
      end
    end
  end

  # --- ทุก action (update? destroy? publish?) × เจ้าของ / คนอื่น / admin / ไม่ login  และทุกสถานะของโพสต์ ---

  test "the owner may update, destroy and publish their post in every status" do
    posts(:post_draft, :post_scheduled_tomorrow, :post_scheduled_overdue, :post_published_last_week).each do |post|
      policy = PostPolicy.new(users(:somchai), post)

      assert policy.update?, "update? #{post.status}"
      assert policy.destroy?, "destroy? #{post.status}"
      assert policy.publish?, "publish? #{post.status}"
    end
  end

  test "another author may not update, destroy or publish someone else's post in any status" do
    posts(:post_draft, :post_scheduled_tomorrow, :post_scheduled_overdue, :post_published_last_week).each do |post|
      policy = PostPolicy.new(users(:malee), post)

      assert_not policy.update?, "update? #{post.status}"
      assert_not policy.destroy?, "destroy? #{post.status}"
      assert_not policy.publish?, "publish? #{post.status}"
    end
  end

  test "admin may update, destroy and publish anyone's post, including one without an owner" do
    posts(:post_draft, :post_scheduled_tomorrow, :post_published_before_login).each do |post|
      policy = PostPolicy.new(users(:boss), post)

      assert policy.update?, "update? #{post.title}"
      assert policy.destroy?, "destroy? #{post.title}"
      assert policy.publish?, "publish? #{post.title}"
    end
  end

  test "a guest may do nothing" do
    policy = PostPolicy.new(nil, posts(:post_draft))

    assert_not policy.update?
    assert_not policy.destroy?
    assert_not policy.publish?
  end

  test "a post without an owner is not anyone's but the admin's" do
    post = posts(:post_published_before_login)

    users(:somchai, :malee).each do |user|
      policy = PostPolicy.new(user, post)

      assert_not policy.update?, user.name
      assert_not policy.destroy?, user.name
      assert_not policy.publish?, user.name
      assert_not PostPolicy.scope(user).exists?(post.id), user.name
    end
  end
end
