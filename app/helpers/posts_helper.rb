module PostsHelper
  # เขียนชื่อคลาสเต็มทุกค่าให้ Tailwind สแกนเจอ (ห้ามต่อ string จาก status)
  STATUS_BADGE_CLASSES = {
    "draft" => "badge badge-ghost",
    "scheduled" => "badge badge-info badge-soft",
    "published" => "badge badge-success badge-soft"
  }.freeze

  # ภาษาไทยไม่เว้นวรรคระหว่างคำ นับคำไม่ได้ จึงประมาณจากจำนวนตัวอักษรของ plain_text
  READING_CHARS_PER_MINUTE = 1_000

  def post_status_badge(post)
    tag.span Post.human_attribute_name("status.#{post.status}"), class: STATUS_BADGE_CLASSES.fetch(post.status)
  end

  # เวลาอ่านโดยประมาณ (นาที) อย่างน้อย 1 นาที  คิดจากเนื้อหาล้วน จึงอยู่ใน cache ของการ์ดได้
  def reading_minutes(post)
    [ (post.plain_text.to_s.length / READING_CHARS_PER_MINUTE.to_f).ceil, 1 ].max
  end
end
