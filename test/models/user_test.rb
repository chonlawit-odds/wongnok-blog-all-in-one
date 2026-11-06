require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "from_keycloak! creates a user from the sub with name, email and role" do
    user = User.from_keycloak!(keycloak_auth_hash(sub: "sub-1", name: "Nok Noi", email: "nok@wongnok.test", roles: %w[ author admin ]))

    assert user.persisted?
    assert_equal [ "sub-1", "Nok Noi", "nok@wongnok.test" ], [ user.keycloak_sub, user.name, user.email ]
    assert user.admin?
  end

  test "from_keycloak! finds by sub and refreshes the profile" do
    assert_no_difference("User.count") do
      User.from_keycloak!(keycloak_auth_hash(sub: users(:somchai).keycloak_sub, name: "สมชาย ใจดี", email: "somchai@new.test"))
    end

    assert_equal [ "สมชาย ใจดี", "somchai@new.test" ], users(:somchai).reload.values_at(:name, :email)
  end

  test "from_keycloak! never matches by email" do
    user = User.from_keycloak!(keycloak_auth_hash(sub: "sub-2", name: "Someone", email: users(:somchai).email))

    assert_not_equal users(:somchai), user
  end

  test "from_keycloak! refuses a blank sub instead of matching an old user without a Keycloak account" do
    assert_raises(ArgumentError) do
      User.from_keycloak!(keycloak_auth_hash(sub: nil, name: users(:somying).name))
    end
  end

  test "name falls back to preferred_username when Keycloak has no full name" do
    user = User.from_keycloak!(keycloak_auth_hash(sub: "sub-3", name: "", preferred_username: "nok"))

    assert_equal "nok", user.name
  end

  test "database enforces the role values" do
    assert_raises(ActiveRecord::StatementInvalid) do
      User.insert!({ keycloak_sub: "sub-4", name: "x", role: "superuser" })
    end
  end

  test "users with content cannot be deleted" do
    assert_not users(:somchai).destroy
    assert users(:somchai).errors.of_kind?(:base, :"restrict_dependent_destroy.has_many")
  end
end
