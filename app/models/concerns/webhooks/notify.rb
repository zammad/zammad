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
      Webhook.find_each do |webhook|
        Webhooks::NotificationJob.perform_later(
          resource_type: self.class.name.underscore,
          resource_id:   id,
          webhook_id:    webhook.id,
          event:         type
        )
      end
    end
  end
end
