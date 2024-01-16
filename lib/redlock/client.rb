# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

##
# Redlock implementation for distributed locking.
#
# TODO: Replace (and remove) this custom class with the existing redlock
#       gem [0], once we get rid of supported linux distributions that are not
#       providing a redis version 6+.
#
#       [0] https://github.com/leandromoreira/redlock-rb
module Redlock
  class Client
    def initialize(server)
      @id = SecureRandom.uuid
      @redis = Redis.new(driver: :hiredis, url: server)
    end

    def lock(resource, ttl, options = {}, &block)
      return extend_ttl(options[:extend]) if options[:extend]
      return if !@redis.set(resource, @id, nx: true, px: ttl)

      if block
        begin
          yield block
        ensure
          unlock({ resource: resource, value: @id })
        end
      else
        { resource: resource, value: @id }
      end
    end

    def unlock(lock_info)
      value = @redis.get(lock_info[:resource])
      return 0 if value != lock_info[:value]

      @redis.del(lock_info[:resource])
    end

    def locked?(resource)
      @redis.exists?(resource)
    end

    private

    def extend_ttl(lock_info)
      return 0 if !locked?(lock_info[:resource])

      value = @redis.get(lock_info[:resource])
      return 0 if value != lock_info[:value]

      ttl = @redis.pttl(lock_info[:resource])
      return if ttl <= 0 || ttl > lock_info[:validity]

      @redis.pexpire(lock_info[:resource], lock_info[:validity])
    end
  end
end
