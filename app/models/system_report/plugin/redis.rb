# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SystemReport::Plugin::Redis < SystemReport::Plugin
  DESCRIPTION = __('Redis version').freeze

  def fetch
    Zammad::Service::Redis.new.info
  rescue
    nil
  end
end
