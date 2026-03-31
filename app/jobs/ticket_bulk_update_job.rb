# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class TicketBulkUpdateJob < ApplicationJob
  include HasActiveJobLock

  TICKETS_PER_JOB_COUNT = 100
  STATUS_UPDATE_INTERVAL = 10

  def lock_key
    user = arguments.dig(0, :user)
    # "TicketBulkUpdateJob/User/1"
    "#{self.class.name}/User/#{user.id}"
  end

  def perform(user:, perform:, ticket_ids:, failed_ticket_ids: [], processed_count: nil, total: nil)
    current_ticket_ids   = ticket_ids.first(TICKETS_PER_JOB_COUNT)
    remaining_ticket_ids = ticket_ids.drop(TICKETS_PER_JOB_COUNT)
    total ||= ticket_ids.size
    processed_count ||= 0

    Ticket.where(id: current_ticket_ids).find_each.with_index(1) do |ticket, i|
      Service::Ticket::Bulk::SingleItemUpdate
        .new(user:, ticket:, perform:)
        .execute
    rescue Service::Ticket::Bulk::SingleItemUpdate::BulkSingleError => e
      failed_ticket_ids << e.record.id
    ensure
      if (i % STATUS_UPDATE_INTERVAL).zero? && i != current_ticket_ids.size
        update_subscription_progress(user, processed_count + i, total)
      end
    end

    processed_count += current_ticket_ids.size

    if remaining_ticket_ids.present?
      self.class.perform_later(
        user:,
        perform:,
        ticket_ids:        remaining_ticket_ids,
        failed_ticket_ids:,
        processed_count:,
        total:,
      )
      return
    end

    create_online_notification(user, total:, failed_ticket_ids:)
    finish_subscription(user, total:, failed_ticket_ids:)
  end

  # Fetches the current running status of the bulk update job for the given user.
  # @param user [User] the user for whom to check the bulk update job status
  # @return [Hash] a hash containing the status (:none, :pending, :running), total count of tickets, and processed count
  def self.fetch_running_status(user)
    lock = ActiveJobLock.find_by(lock_key: "#{name}/User/#{user.id}")
    return { status: 'none' } if !lock

    job = lock.related_job
    return { status: 'none' } if !job

    arguments       = job.payload_object.job_data['arguments'].first
    total           = arguments['total'] || arguments['ticket_ids'].count || 0
    processed_count = arguments['processed_count'] || 0
    status          = job.locked_by.present? || processed_count.nonzero? ? 'running' : 'pending'

    { status:, total:, processed_count: }
  end

  private

  def finish_subscription(user, total:, failed_ticket_ids: [])
    Gql::Subscriptions::User::Current::Ticket::BulkUpdateStatusUpdates
      .trigger(
        {
          status:       failed_ticket_ids.empty? ? 'succeeded' : 'failed',
          failed_count: failed_ticket_ids.count,
          total:
        },
        scope: user.id
      )
  end

  def update_subscription_progress(user, processed_count, total)
    Gql::Subscriptions::User::Current::Ticket::BulkUpdateStatusUpdates
      .trigger(
        { status: 'running', processed_count:, total: },
        scope: user.id
      )
  end

  def create_online_notification(user, total:, failed_ticket_ids: [])
    OnlineNotification.add(
      user_id:       user.id,
      kind:          'bulk_job',
      seen:          false,
      data:          {
        total:,
        failed_count: failed_ticket_ids.count,
      },
      created_by_id: 1, # Show as created by system user with the instance logo
    )
  end
end
