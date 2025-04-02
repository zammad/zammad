# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Zammad
  module Service
    class Redis < ::Redis
      def initialize
        url = ENV['REDIS_URL'].presence || 'redis://localhost:6379'
        driver = url.start_with?('rediss://') ? :ruby : :hiredis

        super(url: url, driver: driver)
      end
    end
  end
end
