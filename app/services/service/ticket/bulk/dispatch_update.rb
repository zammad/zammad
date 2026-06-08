# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Bulk::DispatchUpdate < Service::Base
  BACKGROUND_UPDATE_THRESHOLD = ENV.fetch('ZAMMAD_UI_BULK_BACKGROUND_UPDATE_THRESHOLD', 20).to_i

  requires_current_user!

  attr_reader :selector, :perform

  def initialize(selector:, perform:)
    @selector = selector
    @perform  = perform
  end

  def execute
    background_update? ? schedule_background_update : perform_update_now
  end

  private

  def ticket_ids
    @ticket_ids ||= Service::Ticket::Bulk::Selector
      .with_current_user(current_user)
      .execute(selector:)
  end

  def schedule_background_update
    Gql::Subscriptions::User::Current::Ticket::BulkUpdateStatusUpdates
      .trigger(
        { status: 'pending', total: ticket_ids.size },
        scope: current_user.id
      )

    TicketBulkUpdateJob.perform_later(user: current_user, ticket_ids:, perform:)

    { async: true, total: ticket_ids.size }
  end

  def perform_update_now
    Service::Ticket::Bulk::UpdateInline
      .with_current_user(current_user)
      .execute(ticket_ids:, perform:)
  end

  def background_update?
    ticket_ids.size >= BACKGROUND_UPDATE_THRESHOLD
  end
end
