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
    assert_equal [ posts(:one) ], PostPolicy.scope(users(:somchai)).to_a
    assert_equal Post.count, PostPolicy.scope(users(:boss)).count
    assert_empty PostPolicy.scope(nil)

    Post.find_each do |post|
      users(:somchai, :malee, :boss).each do |user|
        assert_equal PostPolicy.new(user, post).update?, PostPolicy.scope(user).exists?(post.id), "#{user.name} / post #{post.id}"
      end
    end
  end
end
