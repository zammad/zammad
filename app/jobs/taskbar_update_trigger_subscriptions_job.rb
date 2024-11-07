# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# This job retrieves all taskbars associated with the specified taskbar key and activates the related update subscription.
# This allows for updates to taskbar entries, such as cases where a user may lose permissions for a ticket.
class TaskbarUpdateTriggerSubscriptionsJob < ApplicationJob
  include HasActiveJobLock

  def lock_key
    # "TaskbarUpdateTriggerSubscriptionsJob/Ticket-123"
    "#{self.class.name}/#{arguments[0]}"
  end

  def perform(taskbar_key)
    # Trigger taskbar item updates in case the ticket group was changed.
    #   This will make sure a timely update about the loss or gain of ticket access for the client.
    Taskbar.where(key: taskbar_key, app: :desktop).each do |taskbar|
      Gql::Subscriptions::User::Current::TaskbarItemUpdates.trigger_after_update(taskbar)
    end
  end
end
