# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class CacheClearJob < ApplicationJob
  include HasActiveJobLock

  def perform
    # cleanup is not supported by every backend so
    # try only if exists
    Rails.cache.try(:cleanup)
  rescue => e
    Rails.logger.error "Scheduled cache cleanup failed! #{e.inspect}"
  end
end
