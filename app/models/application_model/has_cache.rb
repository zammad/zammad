# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module ApplicationModel::HasCache
  extend ActiveSupport::Concern

  included do
    before_create :cache_delete

    after_create  :cache_delete
    after_update  :cache_delete
    after_touch   :cache_delete
    after_destroy :cache_delete
  end

  def cache_update(o)
    cache_delete if respond_to?('cache_delete')
    o.cache_delete if o.respond_to?('cache_delete')
    true
  end

  def cache_delete
    keys = []

    # delete by id caches
    keys.push "#{self.class}::#{id}"

    # delete by id with attributes_with_association_ids caches
    keys.push "#{self.class}::aws::#{id}"

    # delete by name caches
    if self[:name]
      keys.push "#{self.class}::#{name}"
    end

    # delete by login caches
    if self[:login]
      keys.push "#{self.class}::#{login}"
    end

    keys.each { |key|
      Cache.delete(key)
    }

    # delete old name / login caches
    if changed?
      if changes.key?('name')
        name = changes['name'][0]
        key = "#{self.class}::#{name}"
        Cache.delete(key)
      end
      if changes.key?('login')
        name = changes['login'][0]
        key = "#{self.class}::#{name}"
        Cache.delete(key)
      end
    end
    true
  end

  # methods defined here are going to extend the class, not the instance of it
  class_methods do

    def cache_set(data_id, data)
      key = "#{self}::#{data_id}"
      Cache.write(key, data)
    end

    def cache_get(data_id)
      key = "#{self}::#{data_id}"
      Cache.get(key)
    end
  end
end
