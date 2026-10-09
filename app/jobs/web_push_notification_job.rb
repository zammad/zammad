# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Sends one online notification to one subscribed device, so a retry never
#   reaches the devices that already received it.
class WebPushNotificationJob < ApplicationJob
  # A push that arrives much later than the notification is noise, so the
  #   retries end after about twenty minutes.
  retry_on(Service::User::PushSubscription::Deliver::TemporaryError, attempts: 5, wait: ->(executions) { executions * 2.minutes }) do |job, e|
    Rails.logger.error { "Web push to subscription #{job.arguments.second.id} failed for good: #{e.message}" }
  end

  # The online notification or the subscription was removed before the job ran.
  discard_on ActiveJob::DeserializationError

  # Same window after which the live user avatars show an agent as idle.
  DESKTOP_IDLE_TIME = 5.minutes

  def perform(online_notification, subscription)
    return if !deliverable?(online_notification)

    message = OnlineNotification::PushPayload.new(online_notification).to_h.to_json

    Service::User::PushSubscription::Deliver.execute(subscription:, message:)
  end

  private

  # Checked when the job runs, as access, the account or the notification may
  #   have changed since the notification was created or since the last attempt.
  def deliverable?(online_notification)
    return false if online_notification.seen
    return false if !online_notification.user&.active?
    return false if active_on_desktop?(online_notification.user)

    Pundit.policy(online_notification.user, online_notification).related_accessible?
  rescue ActiveRecord::RecordNotFound
    false
  end

  # The agent sees the notification in the desktop app already. Only actions
  #   such as opening, switching or editing a tab count as contact.
  def active_on_desktop?(user)
    Taskbar.app(:desktop).exists?(user:, last_contact: DESKTOP_IDLE_TIME.ago..)
  end
end
