# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class User::Current::Ticket::BulkUpdateStatusUpdates < BaseSubscription

    description 'Updates for ticket bulk update status changes for the current user.'

    field :bulk_update_status, Gql::Types::Ticket::BulkUpdateStatusType, null: false, description: 'Current status of the bulk update'

    subscription_scope :current_user_id

    requires_permission 'ticket.agent'

    def subscribe
      current_status = TicketBulkUpdateJob.fetch_running_status(context.current_user)

      { bulk_update_status: current_status }
    end

    def update
      {
        bulk_update_status: {
          status:          object[:status],
          total:           object[:total],
          processed_count: object[:processed_count],
          failed_count:    object[:failed_count],
        }.compact
      }
    end
  end
end
