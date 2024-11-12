# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Ticket::ExternalReferences
  class IdoitObjectListInputType < Gql::Types::BaseInputObject
    description 'Represents information to fetch detailed idoit objects for the given idoit object ids or the given ticket'

    argument :ticket_id, GraphQL::Types::ID, required: false, loads: Gql::Types::TicketType, description: 'The related ticket for the idoit objects'
    argument :idoit_object_ids, [Integer], required: false, description: 'The idoit object ids for the detailed list'

    validates required: { one_of: %i[ticket idoit_object_ids] }
  end
end
