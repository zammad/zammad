# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

module ApplicationHelper
  def inline_svg(path)
    File.open("public/assets/images/#{path}", 'rb') do |file|
      raw file.read
    end
  end
end
