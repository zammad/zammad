# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class KeyValueType < Gql::Types::BaseObject

    description 'Key/value type with string values.'

    field :key, String, null: false
    field :value, String, null: true
  end
end
