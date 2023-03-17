# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module ApplicationModel::HasCache
  extend ActiveSupport::Concern

  included do
    before_create :cache_delete
    after_commit :cache_delete
  end

  def cache_update(other)
    cache_delete if respond_to?(:cache_delete)
    other.cache_delete if other.respond_to?(:cache_delete)
    ActiveSupport::CurrentAttributes.clear_all
    true
  end

  def cache_delete
    Rails.cache.delete("#{self.class}::aws::#{id}")
  end
end
