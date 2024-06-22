# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Auth
  class RequestCache < ActiveSupport::CurrentAttributes
    attribute :request_cache

    def self.fetch_value(name)
      self.request_cache ||= {}
      return self.request_cache[name] if !self.request_cache[name].nil?

      self.request_cache[name] = yield
    end

    def self.clear
      self.request_cache = {}
    end
  end
end
