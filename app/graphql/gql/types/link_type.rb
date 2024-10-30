# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class LinkType < Gql::Types::BaseObject
    description 'Links between objects'

    field :source, Gql::Types::LinkObjectType, null: false
    field :target, Gql::Types::LinkObjectType, null: false
    field :type, Gql::Types::Enum::LinkTypeType, null: false
  end
end
