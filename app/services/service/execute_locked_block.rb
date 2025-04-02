# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::ExecuteLockedBlock < Service::Base

  attr_reader :resource, :ttl, :redis_url

  def self.locked?(resource)
    dlm = Redlock::Client.new
    dlm.locked?(resource)
  end

  def self.locked!(resource)
    raise(ExecuteLockedBlockError) if locked?(resource)
  end

  def self.lock(resource, ttl)
    dlm = Redlock::Client.new
    dlm.lock(resource, ttl)
  end

  def self.unlock(lock_info)
    dlm = Redlock::Client.new
    dlm.unlock(lock_info)
  end

  def self.extend(lock_info)
    dlm = Redlock::Client.new
    dlm.lock(nil, nil, extend: lock_info)
  end

  def initialize(resource, ttl)
    super()

    @resource = resource
    @ttl = ttl
  end

  def execute(&)
    dlm = Redlock::Client.new
    dlm.lock(resource, ttl, &)
  end

  class ExecuteLockedBlockError < StandardError
    def initialize(message = __('This resource cannot be locked, because it has already been locked by another process.'))
      super
    end
  end
end
