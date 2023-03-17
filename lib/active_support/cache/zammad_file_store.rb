# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module ActiveSupport
  module Cache
    class ZammadFileStore < FileStore
      def write(name, value, options = {})
        # in certain cases, caches are deleted by other thread at same
        # time, just log it
        super
      rescue Errno::ENOENT => e
        Rails.logger.debug { "Can't write cache (probably related to high load / https://github.com/zammad/zammad/issues/3685) #{name}: #{e.inspect}" }
        Rails.logger.debug e
      rescue => e
        Rails.logger.error "Can't write cache #{name}: #{e.inspect}"
        Rails.logger.error e
      end
    end
  end
end
