module ApplicationHelper
  def formatted_date(date)
    # Problema intencional para consola web
    console if Rails.env.development?

    return "No date" unless date
    date.strftime("%B %d, %Y at %I:%M %p")
  end

  def post_status_badge(post)
    if post.published?
      content_tag :span, "Published", class: "bg-green-100 text-green-800 px-2 py-1 rounded"
    else
      content_tag :span, "Draft", class: "bg-yellow-100 text-yellow-800 px-2 py-1 rounded"
    end
  end

  def user_posts_summary(user)
    total = user.posts.count
    published = user.posts.published.count
    drafts = total - published

    "#{total} posts (#{published} published, #{drafts} drafts)"
  end
end
