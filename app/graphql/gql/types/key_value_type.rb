# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class KeyValueType < Gql::Types::BaseObject

    description 'Key/value type with string values.'

    field :key, String, null: false
    field :value, String
  end
end
