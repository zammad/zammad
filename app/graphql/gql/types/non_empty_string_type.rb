# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class NonEmptyStringType < BaseScalar

    description 'String which must have content'

    def self.coerce_input(input_value, _context = nil)
      raise GraphQL::CoercionError, "#{input_value.inspect} is not a valid NonEmptyString" if input_value.strip.empty?

      input_value
    end
  end
end
