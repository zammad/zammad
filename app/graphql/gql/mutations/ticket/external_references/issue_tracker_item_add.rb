# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::ExternalReferences::IssueTrackerItemAdd < BaseMutation
    description 'Add an issue tracker link to a ticket or just resolve it for ticket creation.'

    argument :ticket_id,          GraphQL::Types::ID, required: false, loads: Gql::Types::TicketType, description: 'The related ticket for the issue tracker items'
    argument :issue_tracker_link, Gql::Types::UriHttpStringType, description: 'The issue tracker link to add'
    argument :issue_tracker_type, Gql::Types::Enum::Ticket::ExternalReferences::IssueTrackerTypeType, description: 'The issue tracker type'

    field :issue_tracker_item, Gql::Types::Ticket::ExternalReferences::IssueTrackerItemType, description: 'The added issue tracker item'

    def authorized?(issue_tracker_link:, issue_tracker_type:, ticket: nil)
      if ticket.present?
        Pundit.authorize(context.current_user, ticket, :agent_update_access?)
      else
        context.current_user.permissions?('ticket.agent')
      end
    end

    def resolve(issue_tracker_link:, issue_tracker_type:, ticket: nil)
      issue_tracker_link_string = issue_tracker_link.to_s

      if ticket.present?
        current_issue_links = ticket.preferences.dig(issue_tracker_type.downcase, :issue_links)

        if current_issue_links.present? && current_issue_links.include?(issue_tracker_link_string)
          return error_response({ field: :link, message: __('The issue reference already exists.') })
        end
      end

      issue_tracker_item_service = Service::Ticket::ExternalReferences::IssueTracker::Item.new(
        type:       issue_tracker_type,
        issue_link: issue_tracker_link_string,
      )

      begin
        item = issue_tracker_item_service.execute
      rescue Exceptions::UnprocessableEntity => e
        return error_response({ field: :link, message: e.message })
      end

      if item.blank?
        return error_response({ field: :link, message: __('The issue reference could not be found.') })
      end

      if ticket.present?
        ticket.preferences[issue_tracker_type.downcase] ||= { issue_links: [] }
        ticket.preferences[issue_tracker_type.downcase][:issue_links].push(item[:url].to_s)

        ticket.save!
      end

      { issue_tracker_item: item }
    end
  end
end
