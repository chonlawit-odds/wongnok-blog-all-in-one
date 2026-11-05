// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Action Text: editor (Trix) + อัปรูปที่แทรกในเนื้อหา
import "trix"
import "@rails/actiontext"

// direct upload ของ <input type=file direct_upload: true>: ส่งไฟล์ขึ้น storage ก่อน แล้วค่อย submit ฟอร์มพร้อม signed_id
import * as ActiveStorage from "@rails/activestorage"
ActiveStorage.start()
