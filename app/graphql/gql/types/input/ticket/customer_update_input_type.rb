# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Ticket
  class CustomerUpdateInputType < Gql::Types::BaseInputObject
    description 'Payload to update a ticket customer'

    argument :customer_id, GraphQL::Types::ID, description: 'The customer of the ticket.', loads: Gql::Types::UserType
    argument :organization_id, GraphQL::Types::ID, required: false, description: 'The organization of the ticket (only needed if the customer belongs to several organizations).', loads: Gql::Types::OrganizationType

  end
end
