ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# test ไม่คุยกับ Keycloak จริง: OmniAuth คืน mock_auth แทน (request phase redirect ไป callback ทันที)
OmniAuth.config.test_mode = true

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # รูปร่างเดียวกับที่ omniauth-keycloak ส่งให้ SessionsController#create
    # extra.raw_info = claim ของ access token (มี realm_access.roles)
    def keycloak_auth_hash(sub:, name:, email: nil, roles: %w[ author ], preferred_username: nil)
      OmniAuth::AuthHash.new(
        provider: "keycloak",
        uid: sub,
        info: { name:, email: },
        extra: { raw_info: { "sub" => sub, "preferred_username" => preferred_username, "realm_access" => { "roles" => roles } } }
      )
    end
  end
end

module SignInHelper
  # login ผ่านเส้นทางเดียวกับของจริง: POST /auth/keycloak -> callback -> SessionsController#create
  def sign_in_as(user, roles: user.admin? ? %w[ author admin ] : %w[ author ])
    OmniAuth.config.mock_auth[:keycloak] = keycloak_auth_hash(sub: user.keycloak_sub, name: user.name, email: user.email, roles:)
    post "/auth/keycloak"
    follow_redirect!
  end
end

class ActionDispatch::IntegrationTest
  include SignInHelper
end
