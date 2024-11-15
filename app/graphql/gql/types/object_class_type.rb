# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# Pseudo string type to make it usable in GQL union types.
module Gql::Types
  class ObjectClassType < Gql::Types::BaseObject
    description 'Object class'

    field :klass, String, description: 'Name of the object class'
    field :info, String, null: true, description: 'Info about the object class'
  end
end
