# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::ObjectManager
  class ScreenAttributesType < Gql::Types::BaseObject

    description 'Screens with underlying attributes.'

    field :name, String, null: false
    field :attributes, [String], null: false
  end
end
