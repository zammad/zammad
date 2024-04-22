# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SystemReport::Plugin::Redis < SystemReport::Plugin
  DESCRIPTION = __('Redis version').freeze

  def fetch
    redis_url = ENV['REDIS_URL'].presence || 'redis://localhost:6379'
    ::Redis.new(driver: :hiredis, url: redis_url).info
  rescue
    nil
  end
end
