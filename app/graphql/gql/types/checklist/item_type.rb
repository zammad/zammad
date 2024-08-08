# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Checklist
  class ItemType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject

    description 'Ticket checklist item'

    field :text, String
    field :checked, Boolean

  end
end
