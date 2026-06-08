# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Zammad
  module Service
    class Redis < ::Redis
      MIN_VERSION = '6'.freeze

      def self.config
        ENV['REDIS_SENTINELS'].present? ? sentinel_config : standalone_config
      end

      def self.standalone_config
        {
          driver: :hiredis,
          url:    ENV['REDIS_URL'].presence || 'redis://localhost:6379',
        }
      end

      def self.sentinel_config
        {
          driver:            :hiredis,
          name:              ENV['REDIS_SENTINEL_NAME'].presence || 'mymaster',
          # This can only be :master, as Zammad needs to read and write.
          role:              :master,
          username:          ENV['REDIS_USERNAME']&.strip,
          password:          ENV['REDIS_PASSWORD']&.strip,
          sentinel_username: ENV['REDIS_SENTINEL_USERNAME']&.strip,
          sentinel_password: ENV['REDIS_SENTINEL_PASSWORD']&.strip,
          sentinels:         ENV['REDIS_SENTINELS'].split(',').map do |s|
            host, port = s.strip.split(':')
            { host:, port: port&.to_i || 26_379 }
          end
        }.compact_blank!
      end

      def initialize
        super(**self.class.config).tap do
          ensure_version!
        end
      end

      private

      def ensure_version!
        current_version = info['redis_version']

        return if Gem::Version.new(current_version) >= Gem::Version.new(MIN_VERSION)

        warn "Error: incompatible Redis version (#{MIN_VERSION}+ required; #{current_version} found)."
        exit 1 # rubocop:disable Rails/Exit
      end
    end
  end
end
