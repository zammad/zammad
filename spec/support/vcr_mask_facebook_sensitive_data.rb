# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

VCR.configure do |c|
  c.before_record do |i|
    if i.response.body.include?('"access_token":"')
      i.response.body.gsub!(%r{"access_token":"[^"]+"}, '"access_token":"***"')
    end
  end
end
