class ApplicationController < ActionController::Base
  include Pagy::Method

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user

  private
    # session อยู่ใน cookie ฝั่งเบราว์เซอร์ (เข้ารหัสแล้ว) จึงเก็บแค่ user_id
    # ไม่เก็บ access / refresh / id token ของ Keycloak: ใช้แค่ตอน callback ยืนยันตัวตนแล้วทิ้ง
    # ไม่ใช้ Current: ส่งต่อผู้ใช้ด้วยตัวแปรตรง ๆ (job ไม่มี request จึงไม่มี current_user ให้พึ่ง)
    def current_user
      return @current_user if defined?(@current_user)

      @current_user = session[:user_id] && User.find_by(id: session[:user_id])
    end

    def require_login
      return if current_user

      # จำหน้าที่จะไป (เฉพาะคำขอแบบอ่าน GET/HEAD) แล้วพากลับหลัง login  SessionsController#create อ่านก่อน reset_session
      session[:return_to] = request.fullpath if request.get? || request.head?
      redirect_to new_session_path, alert: t("sessions.required")
    end
end
