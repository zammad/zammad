# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class UriStringType < BaseScalar

    description 'String representing an URI'

    def self.coerce_input(input_value, _context = nil)
      Addressable::URI.parse(input_value).normalize
    rescue URI::InvalidURIError => e
      raise GraphQL::CoercionError, e.message
    end

    def self.coerce_result(ruby_value, _context = nil)
      Addressable::URI.parse(ruby_value).normalize.to_s
    end
  end
end
