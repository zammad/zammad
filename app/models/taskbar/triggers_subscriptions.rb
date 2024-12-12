# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# Trigger GraphQL subscriptions on ticket changes.
module Taskbar::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    attr_accessor :skip_live_user_trigger, :skip_item_trigger

    # Sends latest live users list to both mobile and desktop apps.
    after_save_commit :trigger_live_user_subscriptions, unless: :skip_live_user_trigger

    # Sends changes in taskbars list to desktop app
    after_create_commit  :trigger_taskbar_item_create_subscriptions,  unless: :skip_item_trigger
    after_update_commit  :trigger_taskbar_item_update_subscriptions,  unless: :skip_item_trigger
    after_destroy_commit :trigger_taskbar_item_destroy_subscriptions, unless: :skip_item_trigger

    # Tells dekstop app that changes are available.
    after_update_commit  :trigger_taskbar_item_state_update_subscriptions
  end

  private

  def trigger_live_user_subscriptions
    return if !saved_change_to_attribute?('preferences')

    Gql::Subscriptions::TicketLiveUserUpdates.trigger(
      self,
      arguments: {
        user_id: Gql::ZammadSchema.id_from_internal_id('User', user_id),
        key:     key,
        app:     app,
      }
    )
  end

  def trigger_taskbar_item_create_subscriptions
    return if app != 'desktop'

    Gql::Subscriptions::User::Current::TaskbarItemUpdates.trigger_after_create(self)
  end

  def trigger_taskbar_item_update_subscriptions
    return if app != 'desktop'

    # See specific subscription for prio changes / list sorting.
    # Active attribute is not sent by this subscription.
    # Nor are live users, which are most of preferences content.
    # However, there is dirty flag in preferences and it is checked separately.
    without_saved_changes_keys = %w[active preferences prio last_contact updated_at]

    if self.class.taskbar_ignore_state_updates_entities.include?(callback)
      without_saved_changes_keys << 'state'
    end

    return if !saved_change_to_dirty? &&
              saved_changes.keys.without(*without_saved_changes_keys).none?

    Gql::Subscriptions::User::Current::TaskbarItemUpdates.trigger_after_update(self)
  end

  def trigger_taskbar_item_destroy_subscriptions
    return if app != 'desktop'

    Gql::Subscriptions::User::Current::TaskbarItemUpdates.trigger_after_destroy(self)
  end

  def trigger_taskbar_item_state_update_subscriptions
    return if !saved_change_to_attribute?('state')
    return if app != 'desktop'

    Gql::Subscriptions::User::Current::TaskbarItemStateUpdates.trigger(
      nil,
      arguments: {
        taskbar_item_id: Gql::ZammadSchema.id_from_internal_id('Taskbar', id),
      }
    )
  end
end
