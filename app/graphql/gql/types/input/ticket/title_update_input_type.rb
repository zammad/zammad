# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Ticket
  class TitleUpdateInputType < Gql::Types::BaseInputObject
    description 'Payload to update a ticket customer'

    argument :title, String, description: 'The title of the ticket.', required: true
  end
end
