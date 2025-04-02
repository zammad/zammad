# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket::ExternalReferences::IssueTrackerItemList < BaseQuery

    description 'Detailed issue tracker items for the given issue tracker links or the given ticket'

    argument :input, Gql::Types::Input::Ticket::ExternalReferences::IssueTrackerListInputType, description: 'The input to fetch detailed issue tracker items for the given issue tracker links or the given ticket'
    argument :issue_tracker_type, Gql::Types::Enum::Ticket::ExternalReferences::IssueTrackerTypeType, description: 'The issue tracker type'

    type [Gql::Types::Ticket::ExternalReferences::IssueTrackerItemType], null: false

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('ticket.agent')
    end

    def resolve(issue_tracker_type:, input:)
      if input.ticket.present?
        Service::Ticket::ExternalReferences::IssueTracker::TicketList
          .new(
            ticket: input.ticket,
            type:   issue_tracker_type
          ).execute
      else
        Service::Ticket::ExternalReferences::IssueTracker::FetchMetadata
          .new(
            type:        issue_tracker_type,
            issue_links: input.issue_tracker_links.map(&:to_s),
          ).execute
      end
    end
  end
end
