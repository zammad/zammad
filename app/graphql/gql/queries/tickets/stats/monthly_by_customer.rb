# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Tickets::Stats::MonthlyByCustomer < Tickets::Stats::BaseMonthly

    description 'Fetch monthly ticket stats by customer'

    argument :customer_id, GraphQL::Types::ID, description: 'Customer to generate stats for', loads: Gql::Types::UserType

    def resolve(customer:)
      resolve_stats(conditions: { 'tickets.customer_id' => customer.id })
    end
  end
end
