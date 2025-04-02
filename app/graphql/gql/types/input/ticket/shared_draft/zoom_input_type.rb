# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class Ticket::SharedDraft::ZoomInputType < Gql::Types::BaseInputObject
    description 'The ticket zoom draft fields'

    argument :form_id, String, description: 'Form ID to copy attachments from'
    argument :ticket_id, GraphQL::Types::ID,
             loads:       Gql::Types::TicketType,
             description: 'Ticket to put the draft into'
    argument :new_article, GraphQL::Types::JSON, description: 'Article content of the draft'
    argument :ticket_attributes, GraphQL::Types::JSON, description: 'Ticket attributes of the draft'
  end
end
