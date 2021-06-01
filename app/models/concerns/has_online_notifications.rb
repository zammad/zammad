# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module HasOnlineNotifications
  extend ActiveSupport::Concern

  included do
    before_destroy :online_notification_destroy
  end

=begin

delete object online notification list, will be executed automatically

  model = Model.find(123)
  model.online_notification_destroy

=end

  def online_notification_destroy
    OnlineNotification.remove(self.class.to_s, id)
    true
  end
end
