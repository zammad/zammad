# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Ticket::Update::BulkUserErrorType < Gql::Types::BaseObject

    description 'Represents an error during a ticket bulk update mutation.'

    field :failed_ticket, Gql::Types::TicketType, description: 'Ticket which caused the bulk update transaction to fail and be rolled back'
    field :message, String, null: false
    field :error_type, String, null: false, description: 'Exception class'
  end
end
