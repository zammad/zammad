# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::OnlineNotification::DeleteAll < Service::Base
  requires_current_user!

  # `delete_all` skips the model callbacks, so the client notification and the
  # subscription trigger have to be sent manually. Without deleted rows there is
  # nothing to notify about - the legacy widget answers `OnlineNotification::changed`
  # with a full refetch, so the push is not free.
  def execute
    deleted = ::OnlineNotification.where(user_id: current_user.id).delete_all

    return true if deleted.zero?

    Sessions.send_to(current_user.id, event: 'OnlineNotification::changed', data: {})
    ::OnlineNotification.trigger_subscriptions(current_user)

    true
  end
end
