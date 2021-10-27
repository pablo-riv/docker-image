module DeviseHelper
  def devise_error_messages!
    return nil if resource.errors.empty?
    messages = resource.errors.full_messages.map { |msg| content_tag(:li, msg) }.join
    html = "<div ><ul class='list-unstyled alert alert-danger'>#{messages}</ul></div>"
    html.html_safe
  end
end