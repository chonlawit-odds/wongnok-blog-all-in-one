require "test_helper"

class FollowerTest < ActiveSupport::TestCase
  test "normalizes email to lowercase without spaces" do
    follower = Follower.create!(email: "  New.Reader@Example.COM ")

    assert_equal "new.reader@example.com", follower.email
  end

  test "requires a valid email" do
    follower = Follower.new(email: "not-an-email")

    assert_not follower.valid?
    assert follower.errors.added?(:email, :invalid, value: "not-an-email")
  end

  test "email is unique regardless of case" do
    follower = Follower.new(email: followers(:ann).email.upcase)

    assert_not follower.valid?
    assert follower.errors.added?(:email, :taken, value: followers(:ann).email)
  end
end
