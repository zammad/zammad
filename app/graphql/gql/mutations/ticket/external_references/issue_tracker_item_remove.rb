# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::ExternalReferences::IssueTrackerItemRemove < BaseMutation
    description 'Removes an issue tracker link from an ticket.'

    argument :ticket_id,          GraphQL::Types::ID, loads: Gql::Types::TicketType, description: 'The related ticket for the issue tracker items'
    argument :issue_tracker_link, Gql::Types::UriHttpStringType, description: 'The issue tracker link to remove'
    argument :issue_tracker_type, Gql::Types::Enum::Ticket::ExternalReferences::IssueTrackerTypeType, description: 'The issue tracker type'

    field :success, Boolean, description: 'Was the mutation successful?'

    def authorized?(ticket:, issue_tracker_link:, issue_tracker_type:)
      Pundit.authorize(context.current_user, ticket, :agent_update_access?)
    end

    def resolve(ticket:, issue_tracker_link:, issue_tracker_type:)
      ticket
        .preferences
        .dig(issue_tracker_type.downcase, :issue_links)
        &.delete issue_tracker_link.to_s

      ticket.save!

      { success: true }
    end
  end
end
