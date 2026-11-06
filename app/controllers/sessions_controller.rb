class SessionsController < ApplicationController
  # callback ที่ผ่าน OmniAuth แล้ว (สร้าง session ได้จริง) จำกัด 10 ครั้งต่อ 3 นาทีต่อ IP
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_session_path, alert: t("sessions.create.rate_limited") }

  # GET /session/new  ปุ่มเข้าสู่ระบบ (POST /auth/keycloak พร้อม CSRF token -> ไปหน้า login ของ Keycloak)
  def new
    redirect_to posts_path if current_user
  end

  # GET /auth/keycloak/callback  OmniAuth แลก code เป็น token และตรวจ state ให้แล้ว
  def create
    user = User.from_keycloak!(request.env.fetch("omniauth.auth"))
    return_to = session[:return_to]

    # กัน session fixation: ทิ้ง session เดิมทั้งก้อน (ได้ session id ใหม่) ก่อนผูกกับผู้ใช้ทุกครั้ง
    reset_session
    session[:user_id] = user.id

    redirect_to return_to.presence || posts_path, notice: t(".success", name: user.name)
  end

  # GET /auth/failure  ผู้ใช้กดยกเลิกที่ Keycloak, state ไม่ตรง, แลก code ไม่ผ่าน ฯลฯ
  def failure
    redirect_to new_session_path, alert: t(".message")
  end

  # DELETE /session  ล้าง session ฝั่งเราแล้วส่งต่อไปปิด session ฝั่ง Keycloak ด้วย
  # (ไม่งั้นกดเข้าสู่ระบบอีกทีจะเข้าเป็นคนเดิมทันทีโดยไม่ถามรหัสผ่าน)
  # ไม่มี id_token_hint เพราะไม่เก็บ token ไว้ Keycloak จึงถามยืนยันอีกครั้งก่อน logout
  def destroy
    reset_session
    redirect_to keycloak_logout_url, allow_other_host: true, status: :see_other, notice: t(".success")
  end

  private
    def keycloak_logout_url
      keycloak = Rails.application.config.x.keycloak
      query = { client_id: keycloak.client_id, post_logout_redirect_uri: posts_url }.to_query

      "#{keycloak.url}/realms/#{keycloak.realm}/protocol/openid-connect/logout?#{query}"
    end
end
