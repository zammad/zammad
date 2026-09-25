# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Ticket
  class CustomerInputType < Gql::Types::BaseInputObject
    description 'Base ticket input customer type'
    one_of

    argument :id, GraphQL::Types::ID, required: false, description: 'The customer of the ticket.', loads: Gql::Types::UserType
    argument :email, String, required: false, description: 'A customer email address.'
    argument :phone, String, required: false, description: 'A customer phone number.'

    transform :unwrap_user

    # A loaded user stands for itself, an address or a number keeps its key so
    #   the service knows which of the two it was handed.
    def unwrap_user(payload)
      payload[:id] || payload.to_h
    end

  end
end
