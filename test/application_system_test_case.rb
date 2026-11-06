require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # job (เช่น broadcast ของ comment) เข้าคิว test adapter ไม่ทำงานเอง
  # ห่อด้วย perform_enqueued_jobs ตรงที่ต้องการให้ทำงานทันที (adapter ใช้ร่วมกับ thread ของ server)
  include ActiveJob::TestHelper

  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1000 ]

  private
    # login ผ่านปุ่มจริงในหน้า login: POST /auth/keycloak -> (OmniAuth test mode) callback -> SessionsController#create
    def sign_in_as(user)
      roles = user.admin? ? %w[ author admin ] : %w[ author ]
      OmniAuth.config.mock_auth[:keycloak] = keycloak_auth_hash(sub: user.keycloak_sub, name: user.name, email: user.email, roles:)

      visit new_session_path
      click_on I18n.t("sessions.new.submit")
      assert_selector "header.navbar", text: user.name
    end
end
