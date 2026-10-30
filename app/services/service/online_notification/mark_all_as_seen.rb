# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::OnlineNotification::MarkAllAsSeen < Service::Base
  requires_current_user!

  # Every unseen notification of the user, not only the ones a client lists:
  #   the list shows a window, and what stays unseen beyond it would surface
  #   again once the cleanup deletes the seen entries in front of it.
  # `update_all` skips the model callbacks, so the client notification and the
  #   subscription trigger are sent manually, once instead of per notification.
  def execute
    marked = ::OnlineNotification
      .where(user_id: current_user.id, seen: false)
      .update_all(seen: true, updated_by_id: current_user.id, updated_at: Time.zone.now) # rubocop:disable Rails/SkipsModelValidations

    return 0 if marked.zero?

    Sessions.send_to(current_user.id, event: 'OnlineNotification::changed', data: {})
    ::OnlineNotification.trigger_subscriptions(current_user)

    marked
  end
end
