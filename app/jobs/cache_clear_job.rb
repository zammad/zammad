# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class CacheClearJob < ApplicationJob
  include HasActiveJobLock

  def perform
    Rails.cache.cleanup
  rescue => e
    Rails.logger.error "Scheduled cache cleanup failed! #{e.inspect}"
  end
end
