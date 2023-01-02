# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CacheClearJob < ApplicationJob
  include HasActiveJobLock

  def perform
    # Memcached does not support clean-up, so only perform it for filesystem cache.
    return if !Rails.cache.is_a? ActiveSupport::Cache::FileStore

    Rails.cache.cleanup
  rescue => e
    Rails.logger.error "Scheduled cache cleanup failed! #{e.inspect}"
  end
end
