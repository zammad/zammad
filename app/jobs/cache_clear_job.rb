# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CacheClearJob < ApplicationJob
  include HasActiveJobLock

  def perform
    # Memcached does not support clean-up, so only perform it for filesystem cache.
    return if !Rails.cache.is_a? ActiveSupport::Cache::FileStore

    Rails.cache.cleanup
  end
end
