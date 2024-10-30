# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::ExternalReferences::IssueTracker::TicketList < Service::Ticket::ExternalReferences::IssueTracker::Base
  attr_reader :ticket

  def initialize(type:, ticket:)
    super(type:)

    @ticket = ticket
  end

  def execute
    Service::CheckFeatureEnabled.new(name: integration_setting_name).execute

    issue_links = ticket.preferences.dig(type.downcase, 'issue_links')

    return [] if issue_links.blank?

    data = issue_tracker_object.issues_by_urls(issue_links)

    # Fix some problems after an issues is moved inside another repository.
    issue_tracker_object.fix_urls_for_ticket(ticket, data[:url_replacements])

    data[:issues] || []
  end
end
