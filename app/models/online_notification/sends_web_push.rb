# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Mirrors every new online notification as a web push message to the
#   devices the recipient subscribed.
module OnlineNotification::SendsWebPush
  extend ActiveSupport::Concern

  included do
    after_create_commit :enqueue_web_push_notification
  end

  private

  def enqueue_web_push_notification
    return if user.blank?

    user.push_subscriptions.find_each do |subscription|
      WebPushNotificationJob.perform_later(self, subscription)
    end
  end
end
