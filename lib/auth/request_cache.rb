# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Auth
  class RequestCache < ActiveSupport::CurrentAttributes
    attribute :request_cache

    def self.fetch_value(name)
      self.request_cache ||= {}
      return request_cache[name] if !request_cache[name].nil?

      request_cache[name] = yield
    end

    def self.clear
      self.request_cache = {}
    end
  end
end
