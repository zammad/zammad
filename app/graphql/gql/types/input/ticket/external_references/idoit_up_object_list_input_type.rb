# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Ticket::ExternalReferences
  class IdoitUpObjectListInputType < Gql::Types::BaseInputObject
    description 'Represents information to fetch detailed i-doit up objects for the given i-doit up object ids or the given ticket'

    argument :ticket_id,           GraphQL::Types::ID, required: false, loads: Gql::Types::TicketType, description: 'The related ticket for the i-doit up objects'
    argument :idoit_up_object_ids, [String], required: false, description: 'The i-doit up object ids for the detailed list'

    validates required: { one_of: %i[ticket idoit_up_object_ids] }
  end
end
