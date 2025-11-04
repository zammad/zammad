# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# This job retrieves all taskbars associated with the specified taskbar key and activates the related update subscription.
# This allows for updates to taskbar entries, such as cases where a user may lose permissions for a ticket.
class TaskbarUpdateTriggerSubscriptionsJob < ApplicationJob
  include HasActiveJobLock

  def lock_key
    # "TaskbarUpdateTriggerSubscriptionsJob/Ticket-123"
    "#{self.class.name}/#{arguments[0]}"
  end

  def perform(taskbar_key, record, changed_keys)
    # When group_id is changed, we always trigger the subscription, because it could be a permission change for
    # the taskbar user.
    always_trigger_subscription = changed_keys.include?('group_id')

    Taskbar.where(key: taskbar_key, app: :desktop).each do |taskbar|

      # Always check if the notify flag should be set to true.
      # This happens when the taskbar's user is a different user than the record's updated by user.
      if !taskbar.notify && record && taskbar.user_id != record.updated_by_id
        taskbar.update!(notify: true)

        # When notify is set, it will already trigger the subscription automatically.
        next
      end

      # When notify is not changed, but always_trigger_subscription is true, manually trigger the subscription.
      if always_trigger_subscription
        Gql::Subscriptions::User::Current::TaskbarItemUpdates.trigger_after_update(taskbar)
      end
    end
  end
end
