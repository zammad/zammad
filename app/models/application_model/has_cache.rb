# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ApplicationModel::HasCache
  extend ActiveSupport::Concern

  included do
    before_create :cache_delete
    after_commit :cache_delete
  end

  def cache_update(other)
    cache_delete if respond_to?('cache_delete')
    other.cache_delete if other.respond_to?('cache_delete')
    true
  end

  def cache_delete
    cache_keys = []

    # delete by id with attributes_with_association_ids caches
    cache_keys.push "#{self.class}::aws::#{id}"

    # delete caches of lookup_keys (e.g. id, name, email, login, number)
    self.class.lookup_keys.each do |lookup_key|
      cache_keys.push "#{self.class}::#{self[lookup_key]}"

      next if !saved_changes? || !saved_changes.key?(lookup_key)

      obsolete_lookup_key = saved_changes[lookup_key][0]
      cache_keys.push "#{self.class}::#{obsolete_lookup_key}"
    end

    cache_keys.each do |key|
      Cache.delete(key)
    end

    true
  end

  # methods defined here are going to extend the class, not the instance of it
  class_methods do

    def cache_set(data_id, data)
      key = "#{self}::#{data_id}"
      # cache for 4 hours max to lower impact of race conditions
      Cache.write(key, data, expires_in: 4.hours)
    end

    def cache_get(data_id)
      key = "#{self}::#{data_id}"
      Cache.read(key)
    end
  end
end
