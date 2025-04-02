# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Ticket
  class CustomerInputType < Gql::Types::BaseInputObject
    description 'Base ticket input customer type'
    one_of

    argument :id, GraphQL::Types::ID, required: false, description: 'The customer of the ticket.', loads: Gql::Types::UserType
    argument :email, String, required: false, description: 'A customer email address.'

    transform :flatten

    def flatten(payload)
      payload.to_h.flatten.last
    end

  end
end
