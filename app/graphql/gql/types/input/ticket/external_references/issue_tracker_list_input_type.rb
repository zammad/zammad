# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Ticket::ExternalReferences
  class IssueTrackerListInputType < Gql::Types::BaseInputObject
    description 'Represents information to fetch detailed issue tracker items for the given issue tracker links or the given ticket'

    argument :ticket_id, GraphQL::Types::ID, required: false, loads: Gql::Types::TicketType, description: 'The related ticket for the issue tracker items'
    argument :issue_tracker_links, [Gql::Types::UriHttpStringType], required: false, description: 'The issue tracker links for the detailed list'

    validates required: { one_of: %i[ticket issue_tracker_links] }
  end
end
