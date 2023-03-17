# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class BinaryStringType < BaseScalar

    description 'String with binary data, base64 encoded for transport (data: URL prefix is optional)'

    def self.coerce_input(input_value, _context = nil)
      # Cut out prefix of data: url if needed (in-place to save memory).
      input_value.sub!(%r{data:.*?base64,}, '')
      Base64.strict_decode64(input_value)
    end

    def self.coerce_result(ruby_value, _context = nil)
      Base64.strict_encode64(ruby_value)
    end
  end
end
