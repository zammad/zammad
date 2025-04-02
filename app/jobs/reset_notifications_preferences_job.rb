# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ResetNotificationsPreferencesJob < ApplicationJob
  include HasActiveJobLock

  # @param send_to_when_done [Integer] ID of user to notify after job is done
  def perform(send_to_when_done: nil)
    users_scope.find_each do |user|
      User.reset_notifications_preferences! user
    end

    return if !send_to_when_done

    Sessions.send_to(send_to_when_done, { event: 'ticket_agent_default_notifications_applied' })
  end

  private

  def users_scope
    User.with_permissions 'ticket.agent'
  end
end
