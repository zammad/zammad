# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ActiveSupport
  module Cache
    class ZammadFileStore < FileStore
      def write(name, value, options = {})
        # in certain cases, caches are deleted by other thread at same
        # time, just log it
        super
      rescue => e
        Rails.logger.error "Can't write cache #{key}: #{e.inspect}"
        Rails.logger.error e
      end
    end
  end
end
