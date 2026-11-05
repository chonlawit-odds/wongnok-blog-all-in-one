module PostsHelper
  # เขียนชื่อคลาสเต็มทุกค่าให้ Tailwind สแกนเจอ (ห้ามต่อ string จาก status)
  STATUS_BADGE_CLASSES = {
    "draft" => "badge badge-ghost",
    "scheduled" => "badge badge-info badge-soft",
    "published" => "badge badge-success badge-soft"
  }.freeze

  def post_status_badge(post)
    tag.span Post.human_attribute_name("status.#{post.status}"), class: STATUS_BADGE_CLASSES.fetch(post.status)
  end
end
