class User < ApplicationRecord
  # realm role ของ Keycloak ที่ทำให้เป็น admin (ดู keycloak/wongnok-realm.json)
  KEYCLOAK_ADMIN_ROLE = "admin"

  # โพสต์และ comment เป็นเนื้อหาที่คนอื่นอ่านอยู่ ลบผู้ใช้ทิ้งเฉย ๆ ไม่ได้ ต้องย้ายเจ้าของก่อน
  has_many :posts, dependent: :restrict_with_error
  has_many :comments, dependent: :restrict_with_error

  # เก็บเป็น string คู่กับ check constraint users_role_valid  ค่าจริงมาจาก Keycloak ทุกครั้งที่ login
  enum :role, { author: "author", admin: "admin" }, default: :author, validate: true

  validates :name, presence: true

  # หา-หรือ-สร้าง จาก sub ของ Keycloak เท่านั้น (ไม่เปลี่ยนตลอดอายุบัญชี)
  # ไม่หาจากอีเมล: อีเมลแก้ได้และอาจไปตรงกับบัญชีอื่น = ยึดบัญชีคนอื่นได้
  # ชื่อ อีเมล และ role อัปเดตตาม Keycloak ทุกครั้ง (ถอด admin ที่ Keycloak แล้ว login รอบหน้าก็ไม่ใช่ admin)
  # auth.extra.raw_info = access token ที่ omniauth-keycloak ถอดและตรวจลายเซ็นกับ JWKS ของ realm แล้ว
  # ใช้อ่าน claim ฝั่ง server ตอน callback เท่านั้น ไม่เก็บ token ไว้ที่ไหน
  def self.from_keycloak!(auth)
    # sub ว่างต้องหยุด: find_by(keycloak_sub: nil) จะไปเจอผู้ใช้เดิมที่ไม่มีบัญชี Keycloak
    sub = auth.uid.presence or raise ArgumentError, "Keycloak did not return a sub"
    claims = auth.extra&.raw_info || {}
    roles = Array(claims.dig("realm_access", "roles"))

    attributes = {
      name: auth.info&.name.presence || claims["preferred_username"].presence || sub,
      email: auth.info&.email.presence,
      role: roles.include?(KEYCLOAK_ADMIN_ROLE) ? :admin : :author
    }

    user = find_or_create_by!(keycloak_sub: sub) { |new_user| new_user.assign_attributes(attributes) }
    user.update!(attributes)
    user
  rescue ActiveRecord::RecordNotUnique
    # login ครั้งแรกพร้อมกันสองแท็บ: อีกแท็บสร้างไปก่อนแล้ว (unique index ตัดสิน) รอบนี้จะหาเจอ
    retry
  end
end
