require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module WongnokBlogAllInOne
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Asia/Bangkok"
    # config.eager_load_paths << Rails.root.join("extras")

    # ข้อความที่ผู้ใช้เห็นเป็นภาษาไทย (คำแปลของ Rails มาจาก gem rails-i18n)
    config.i18n.available_locales = %i[th en]
    config.i18n.default_locale = :th

    # ไม่เก็บ variant ลงตาราง active_storage_variant_records
    # ถ้าเปิด (ค่า default) with_attached_cover จะ preload variant_records + preview_image เพิ่มอีก 2-4 query
    # ทั้งที่ URL ของรูปย่อ (redirect) ไม่ได้ใช้ หน้า index เลยเกิน 6 query
    # แลกกับ: ตอนเปิดรูป Rails เช็กว่ามี variant แล้วหรือยังด้วย HEAD ไปที่ MinIO แทนการถาม DB
    config.active_storage.track_variants = false
  end
end
