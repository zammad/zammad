# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module ApplicationModel::HasRequestCache
  extend ActiveSupport::Concern

  included do
    after_commit :clear_request_cache
  end

  def clear_request_cache
    Auth::RequestCache.clear
  end
end
