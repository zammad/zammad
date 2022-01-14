# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

# Cache.get => read alias for backwards compatibility
# Even if main codebase is migrated, custom addons may still use old syntax!
module ActiveSupport
  module Cache
    class Store
      def get(key)
        ActiveSupport::Deprecation.warn("Method 'get' is deprecated. Please use 'Cache.read' instead.")

        read(key)
      end
    end
  end
end
