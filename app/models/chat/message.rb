class Chat::Message < ApplicationModel
  include HtmlSanitized

  sanitized_html :content
end
