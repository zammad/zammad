# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module Webhooks
  module Notify
    extend ActiveSupport::Concern

    included do
      after_create :schedule_webhook_notification_create
      after_update :schedule_webhook_notification_update
      after_destroy :schedule_webhook_notification_destroy
    end

    def schedule_webhook_notification_create
      schedule_webhook_notification('created')
    end

    def schedule_webhook_notification_update
      schedule_webhook_notification('updated')
    end

    def schedule_webhook_notification_destroy
      schedule_webhook_notification('destroyed')
    end

    private

    def schedule_webhook_notification(type)
      notification_id = SecureRandom.uuid

      Webhook.find_each do |webhook|
        Webhooks::NotificationJob.perform_later(
          o_id:            id,
          object:          self.class.name,
          event:           type,
          webhook_id:      webhook.id,
          notification_id: notification_id,
          occurred_at:     Time.zone.now.as_json
        )
      end
    end
  end
end
