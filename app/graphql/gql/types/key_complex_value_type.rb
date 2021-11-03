# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Gql::Types
  class KeyComplexValueType < Gql::Types::BaseObject

    def self.requires_authentication?
      false
    end

    description 'Key/value type with complex values.'

    field :key, String, null: false
    field :value, GraphQL::Types::JSON, null: true
  end
end
