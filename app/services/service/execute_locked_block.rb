# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::ExecuteLockedBlock < Service::Base
  REDIS_URL = ENV['REDIS_URL'].presence || 'redis://localhost:6379'

  attr_reader :resource, :ttl, :redis_url

  def self.locked?(resource, redis_url: REDIS_URL)
    dlm = Redlock::Client.new(redis_url)
    dlm.locked?(resource)
  end

  def self.locked!(resource, redis_url: REDIS_URL)
    raise(ExecuteLockedBlockError) if locked?(resource, redis_url: redis_url)
  end

  def self.lock(resource, ttl, redis_url: REDIS_URL)
    dlm = Redlock::Client.new(redis_url)
    dlm.lock(resource, ttl)
  end

  def self.unlock(lock_info, redis_url: REDIS_URL)
    dlm = Redlock::Client.new(redis_url)
    dlm.unlock(lock_info)
  end

  def self.extend(lock_info, redis_url: REDIS_URL)
    dlm = Redlock::Client.new(redis_url)
    dlm.lock(nil, nil, extend: lock_info)
  end

  def initialize(resource, ttl, redis_url: REDIS_URL)
    super()

    @resource = resource
    @ttl = ttl
    @redis_url = redis_url
  end

  def execute(&)
    dlm = Redlock::Client.new(redis_url)
    dlm.lock(resource, ttl, &)
  end

  class ExecuteLockedBlockError < StandardError
    def initialize(message = __('This resource cannot be locked, because it has already been locked by another process.'))
      super
    end
  end
end
