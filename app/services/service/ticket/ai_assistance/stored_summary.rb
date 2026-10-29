# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Returns the stored, current summary of a ticket and never triggers a generation,
#   so it is safe to call wherever a summary is only nice to have (e.g. popovers).
class Service::Ticket::AIAssistance::StoredSummary < Service::Base
  attr_reader :ticket

  requires_current_user!

  def initialize(ticket:)
    @ticket = ticket
  end

  def execute
    return if !Setting.get('ai_assistance_ticket_summary') || !Setting.get('ai_provider')
    return if !TicketPolicy.new(current_user, ticket).agent_read_access?

    Service::Ticket::AIAssistance::Summarize
      .with_current_user(current_user)
      .execute(
        ticket:,
        locale:               current_user.locale,
        persistence_strategy: :stored_only,
      )
      &.content
      .presence
  end
end
