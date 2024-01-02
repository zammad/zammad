# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket::Article
  class TypeType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject

    description 'Ticket article types'

    field :name, String
    field :communication, Boolean
  end
end
