# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module Webhooks
  module Notify
    extend ActiveSupport::Concern

    included do
      after_create   :schedule_webhook_notification_create
      after_update   :schedule_webhook_notification_update
      before_destroy :schedule_webhook_notification_destroy
    end

    def schedule_webhook_notification_create

    end

    def schedule_webhook_notification_update

    end

    def schedule_webhook_notification_destroy

    end
  end
end
