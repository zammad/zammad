class Chat::Message < ApplicationModel
  include ChecksHtmlSanitized

  sanitized_html :content
end
