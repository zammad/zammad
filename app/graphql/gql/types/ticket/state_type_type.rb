# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket
  class StateTypeType < Gql::Types::BaseObject
    include Gql::Concern::IsModelObject

    description 'Ticket state types'

    field :name, String, null: false
    field :note, String, null: true
  end
end
