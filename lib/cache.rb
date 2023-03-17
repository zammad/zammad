# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Cache = Class.new do
  def method_missing(method, ...)
    super if !respond_to_missing? method

    ActiveSupport::Deprecation.warn("The method 'Cache.#{method}' is deprecated. Use 'Rails.cache.#{method}' instead.")
    Rails.cache.send(method, ...)
  end

  def respond_to_missing?(...)
    Rails.cache.respond_to?(...)
  end
end.new
