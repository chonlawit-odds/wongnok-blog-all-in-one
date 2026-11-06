require "test_helper"

class CommentPolicyTest < ActiveSupport::TestCase
  test "owner and admin may destroy, others and guests may not" do
    comment = comments(:one) # ของ somchai

    assert CommentPolicy.new(users(:somchai), comment).destroy?
    assert CommentPolicy.new(users(:boss), comment).destroy?
    assert_not CommentPolicy.new(users(:malee), comment).destroy?
    assert_not CommentPolicy.new(nil, comment).destroy?
  end

  test "old comments from before login existed are admin only" do
    assert CommentPolicy.new(users(:boss), comments(:two)).destroy?
    assert_not CommentPolicy.new(users(:somchai), comments(:two)).destroy?
  end

  test "scope follows the same rule as destroy?" do
    assert_equal [ comments(:one) ], CommentPolicy.scope(users(:somchai)).to_a
    assert_equal Comment.count, CommentPolicy.scope(users(:boss)).count
    assert_empty CommentPolicy.scope(users(:malee))
    assert_empty CommentPolicy.scope(nil)
  end
end
