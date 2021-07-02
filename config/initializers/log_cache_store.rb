# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

if Rails.application.config.cache_store.first.eql? :mem_cache_store
  Rails.logger.info 'Using memcached as Rails cache store.'
else
  Rails.logger.info "Using Zammad's file store as Rails cache store."
end
