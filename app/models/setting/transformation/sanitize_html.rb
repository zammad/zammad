# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Setting::Transformation::SanitizeHtml < Setting::Transformation::Base
  def run
    update_value sanitized_value
  end

  private

  def sanitized_value
    HtmlSanitizer::Strict
      .new(no_images: true)
      .sanitize(value)
      .strip
  end
end
