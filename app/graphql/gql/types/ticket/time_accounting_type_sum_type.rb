# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket
  class TimeAccountingTypeSumType < Gql::Types::BaseObject
    description 'Ticket time accounting - sum per type'

    field :name, String, null: false
    field :time_unit, Float, null: false
  end
end
