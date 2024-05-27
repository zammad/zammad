# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class UriHttpStringType < UriStringType

    description 'String representing an HTTP URI'

    def self.coerce_input(input_value, context = nil)
      uri = super
      raise GraphQL::CoercionError, 'URI scheme must be HTTP or HTTPS' if %w[http https].exclude?(uri.scheme)

      uri
    end
  end
end
