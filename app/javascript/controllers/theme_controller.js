import { Controller } from "@hotwired/stimulus"

// สลับธีมสว่าง/มืด  (ใช้กับปุ่มใน app/views/shared/_navbar.html.erb)
// - ตั้ง data-theme บน <html> ให้เปลี่ยนทั้งเว็บ
//   Turbo Drive เปลี่ยนแค่ <body> ค่านี้จึงอยู่ต่อเวลากดลิงก์ไปหน้าอื่น
// - จำธีมที่เลือกไว้ใน localStorage แล้วใส่กลับตอนโหลดหน้าใหม่ (refresh)
// - ถ้ายังไม่เคยเลือก ใช้ธีมตามเครื่อง (daisyUI ตั้ง dark เป็น --prefersdark)
const STORAGE_KEY = "theme"
const THEMES = ["light", "dark"]

export default class extends Controller {
  static targets = ["toggle"]

  connect() {
    const saved = this.#storedTheme()
    if (saved) this.#apply(saved)

    this.toggleTarget.checked = this.#currentTheme() === "dark"
  }

  toggle() {
    const theme = this.toggleTarget.checked ? "dark" : "light"
    this.#apply(theme)

    try {
      localStorage.setItem(STORAGE_KEY, theme)
    } catch {
      // บันทึกไม่ได้ (เช่น ผู้ใช้ปิด storage) ก็ยังสลับได้ แค่ refresh แล้วไม่จำ
    }
  }

  #apply(theme) {
    document.documentElement.dataset.theme = theme
  }

  #storedTheme() {
    try {
      const theme = localStorage.getItem(STORAGE_KEY)
      return THEMES.includes(theme) ? theme : null
    } catch {
      return null
    }
  }

  #currentTheme() {
    return document.documentElement.dataset.theme ||
      (window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light")
  }
}
