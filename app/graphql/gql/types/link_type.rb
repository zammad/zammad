# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class LinkType < Gql::Types::BaseObject
    description 'Links between objects'

    field :item, Gql::Types::LinkObjectType, null: false
    field :type, Gql::Types::Enum::LinkTypeType, null: false
  end
end
