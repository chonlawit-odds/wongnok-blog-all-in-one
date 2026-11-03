import { Controller } from "@hotwired/stimulus"

// ตัวนับตัวอักษรของช่องพิมพ์ แสดงเป็น "12 / 1000"  (ใช้กับ app/views/comments/_form.html.erb)
//
// ผูก listener เองใน connect() จึงต้องถอดออกใน disconnect()
// controller ถูก connect ซ้ำได้กับ element เดิม (เช่น Turbo กู้หน้าจาก cache)
// ถ้าไม่ถอด listener จะซ้อนกันและค้างอ้าง controller ตัวเก่าไว้
export default class extends Controller {
  static targets = ["input", "output"]
  static values = { max: Number }

  connect() {
    this.input = this.inputTarget
    this.handleInput = () => this.update()
    this.input.addEventListener("input", this.handleInput)
    this.update()
  }

  disconnect() {
    this.input.removeEventListener("input", this.handleInput)
    this.input = null
    this.handleInput = null
  }

  update() {
    // .length นับแบบเดียวกับ maxlength ของ textarea (สระ/วรรณยุกต์ไทยนับแยกตัว เหมือน String#length ฝั่ง Ruby)
    this.outputTarget.textContent = `${this.input.value.length} / ${this.maxValue}`
  }
}
