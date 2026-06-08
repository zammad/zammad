# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket
  class StatsMonthlyType < Gql::Types::BaseObject
    description 'Monthly ticket stats'

    field :year, String, null: false
    field :month_number, String, null: false
    field :month_label, String, null: false
    field :tickets_created, Integer, null: false
    field :tickets_closed, Integer, null: false
  end
end
