# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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

      alias clear_original clear

      # Running systems can access the caches while clearing so it can
      # lead to exceptions. The retry will help to stabilize this a bit.
      def clear
        retries = 0
        begin
          clear_original
        rescue
          sleep 0.5
          retries += 1
          retry if retries < 3
          Rails.logger.error 'Rails.cache.clear failed 3 times to clear the zammad file store.'
        end
      end
    end
  end
end
