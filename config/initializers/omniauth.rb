# login ผ่าน Keycloak (OpenID Connect, authorization code flow)
# - KEYCLOAK_URL มาจาก env (เครื่อง dev/test ไม่ตั้งก็ได้ ใช้ Keycloak ใน compose.yaml)
# - client secret อยู่ใน rails credentials (keycloak.client_secret) ไม่เขียนลงไฟล์ตรง ๆ
# - omniauth-rails_csrf_protection: เริ่ม login ได้เฉพาะ POST /auth/keycloak ที่มี CSRF token
#   (GET ถูกปิดตั้งแต่ OmniAuth 2 กันเว็บอื่นแอบพาเบราว์เซอร์มา login เป็นบัญชีของคนร้าย)
Rails.application.config.x.keycloak = ActiveSupport::OrderedOptions.new.merge!(
  url: ENV.fetch("KEYCLOAK_URL") { "http://localhost:8080" if Rails.env.local? },
  realm: "wongnok",
  client_id: "wongnok-blog"
)

Rails.application.config.middleware.use OmniAuth::Builder do
  keycloak = Rails.application.config.x.keycloak

  provider :keycloak_openid, keycloak.client_id, Rails.application.credentials.dig(:keycloak, :client_secret),
           name: "keycloak",
           scope: "openid profile email",
           # Keycloak 17+ ไม่มี /auth นำหน้าแล้ว
           client_options: { site: keycloak.url, realm: keycloak.realm, base_url: "" }
end

# ยกเลิก/ล้มเหลวที่ Keycloak: พาไป /auth/failure ทุก environment (ค่าเริ่มต้นของ development คือ raise)
OmniAuth.config.on_failure = ->(env) { OmniAuth::FailureEndpoint.new(env).redirect_to_failure }
OmniAuth.config.logger = Rails.logger
