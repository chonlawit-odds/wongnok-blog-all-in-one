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
    assert_equal [ comments(:comment_by_malee_on_somchai_post) ], CommentPolicy.scope(users(:malee)).to_a
    assert_empty CommentPolicy.scope(nil)

    Comment.find_each do |comment|
      users(:somchai, :malee, :boss).each do |user|
        assert_equal CommentPolicy.new(user, comment).destroy?, CommentPolicy.scope(user).exists?(comment.id),
                     "#{user.name} / comment #{comment.id}"
      end
    end
  end

  # --- เจ้าของ comment / คนอื่น (รวมเจ้าของโพสต์) / admin ---

  test "the comment's owner may destroy it" do
    assert CommentPolicy.new(users(:malee), comments(:comment_by_malee_on_somchai_post)).destroy?
  end

  test "the post's owner may not destroy someone else's comment on their post" do
    # สิทธิ์ผูกกับเจ้าของ comment ไม่ใช่เจ้าของโพสต์
    comment = comments(:comment_by_malee_on_somchai_post)
    assert_equal users(:somchai), comment.post.user

    assert_not CommentPolicy.new(users(:somchai), comment).destroy?
  end

  test "admin may destroy any comment, including one not backfilled yet" do
    assert CommentPolicy.new(users(:boss), comments(:comment_by_malee_on_somchai_post)).destroy?
    assert CommentPolicy.new(users(:boss), comments(:comment_before_backfill)).destroy?
  end

  test "a comment without a user yet belongs to no author" do
    comment = comments(:comment_before_backfill)

    users(:somchai, :malee).each do |user|
      assert_not CommentPolicy.new(user, comment).destroy?, user.name
    end
    assert_not CommentPolicy.new(nil, comment).destroy?
  end
end
