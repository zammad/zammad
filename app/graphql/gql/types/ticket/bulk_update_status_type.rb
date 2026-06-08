# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket
  class BulkUpdateStatusType < Gql::Types::BaseObject
    description 'Ticket bulk update status information'

    field :status, Gql::Types::Enum::BulkUpdateStatusStatusType, null: false, description: 'Current status of the bulk update'
    field :total, Integer, null: true, description: 'Total number of tickets to be updated'
    field :processed_count, Integer, null: true, description: 'Number of tickets processed so far'
    field :failed_count, Integer, null: true, description: 'Number of tickets that failed to update'
  end
end
