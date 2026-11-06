require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "first login creates the user from the Keycloak sub and signs in" do
    assert_difference("User.count") do
      login_with keycloak_auth_hash(sub: "new-sub", name: "Nok Noi", email: "nok@wongnok.test")
    end

    assert_redirected_to posts_url
    assert User.find_by!(keycloak_sub: "new-sub").author?
    follow_redirect!
    assert_select "header.navbar", text: /Nok Noi/
  end

  test "the same sub with a changed email is the same user (found by sub, not by email)" do
    assert_no_difference("User.count") do
      login_with keycloak_auth_hash(sub: users(:somchai).keycloak_sub, name: "Somchai J.", email: "new@wongnok.test")
    end

    assert_equal "new@wongnok.test", users(:somchai).reload.email
    assert_equal users(:somchai).id, session[:user_id]
  end

  test "a new sub carrying someone else's email gets its own account, not theirs" do
    assert_difference("User.count") do
      login_with keycloak_auth_hash(sub: "another-sub", name: "Fake Somchai", email: users(:somchai).email)
    end

    assert_not_equal users(:somchai).id, session[:user_id]
  end

  test "role follows the Keycloak realm role on every login" do
    login_with keycloak_auth_hash(sub: users(:malee).keycloak_sub, name: "Malee", roles: %w[ author admin ])
    assert users(:malee).reload.admin?

    login_with keycloak_auth_hash(sub: users(:malee).keycloak_sub, name: "Malee", roles: %w[ author ])
    assert users(:malee).reload.author?
  end

  test "login resets the session (new session id) and still returns to the page that asked for login" do
    get new_post_url
    assert_redirected_to new_session_url
    session_id_before = session.id.to_s

    sign_in_as users(:somchai)

    assert_not_equal session_id_before, session.id.to_s
    assert_redirected_to new_post_url
  end

  test "session keeps only the user id, no Keycloak tokens" do
    sign_in_as users(:somchai)

    assert_empty session.to_hash.keys - %w[ session_id user_id flash _csrf_token ]
  end

  test "failure from Keycloak goes back to the login page with a message" do
    OmniAuth.config.mock_auth[:keycloak] = :access_denied
    post "/auth/keycloak"
    follow_redirect! # -> /auth/keycloak/callback
    follow_redirect! # -> /auth/failure
    follow_redirect! # -> /session/new

    assert_equal new_session_path, path
    assert_select "[role=alert]", I18n.t("sessions.failure.message")
    assert_nil session[:user_id]
  end

  test "logout clears the session and ends the Keycloak session too" do
    sign_in_as users(:somchai)

    delete session_url

    assert_response :see_other
    assert_match %r{\Ahttp://localhost:8080/realms/wongnok/protocol/openid-connect/logout\?}, response.location
    assert_includes response.location, "client_id=wongnok-blog"
    assert_nil session[:user_id]
  end

  test "rate limit: the 11th login within 3 minutes is refused" do
    with_counting_rate_limit_store do
      10.times { sign_in_as users(:somchai) }
      assert_redirected_to posts_url

      sign_in_as users(:somchai)
      assert_redirected_to new_session_url
      assert_equal I18n.t("sessions.create.rate_limited"), flash[:alert]
    end
  end

  private
    def login_with(auth)
      OmniAuth.config.mock_auth[:keycloak] = auth
      post "/auth/keycloak"
      follow_redirect!
    end

    # rate_limit จับ store ไว้ตอนโหลดคลาส (test ใช้ :null_store ที่ไม่นับอะไรเลย)
    # จึงให้ store ตัวนั้นนับด้วย MemoryStore ชั่วคราวเฉพาะ test นี้
    def with_counting_rate_limit_store
      counter = ActiveSupport::Cache::MemoryStore.new
      store = SessionsController.cache_store
      store.define_singleton_method(:increment) { |*args, **options| counter.increment(*args, **options) }
      yield
    ensure
      store.singleton_class.remove_method(:increment)
    end
end
