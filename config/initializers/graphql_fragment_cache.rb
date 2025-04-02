# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

GraphQL::FragmentCache.configure do |config|
  config.cache_store = Rails.cache
  config.namespace   = 'graphql-fragment_cache'
end
