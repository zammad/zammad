# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module ApplicationHelper
  def icons_url
    Auth::RequestCache.fetch_value('icons_url') do
      "assets/images/icons.svg?#{Rails.public_path.join('assets/images/icons.svg').mtime.to_i}"
    end
  end
end
