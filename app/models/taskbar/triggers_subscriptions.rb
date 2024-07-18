# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# Trigger GraphQL subscriptions on ticket changes.
module Taskbar::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    attr_accessor :skip_trigger

    after_commit :trigger_live_user_subscriptions
    after_create_commit  :trigger_taskbar_item_create_subscriptions,  unless: :skip_trigger
    after_update_commit  :trigger_taskbar_item_update_subscriptions,  unless: :skip_trigger
    after_destroy_commit :trigger_taskbar_item_destroy_subscriptions, unless: :skip_trigger

    after_update_commit  :trigger_taskbar_item_state_update_subscriptions
  end

  private

  def trigger_live_user_subscriptions
    return true if !saved_change_to_attribute?('preferences')

    # For now it's only needed in the mobile view context.
    return true if !app.eql?('mobile') && !persisted?

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
    Gql::Subscriptions::User::Current::TaskbarItemUpdates.trigger_after_create(self)
  end

  def trigger_taskbar_item_update_subscriptions
    Gql::Subscriptions::User::Current::TaskbarItemUpdates.trigger_after_update(self)
  end

  def trigger_taskbar_item_destroy_subscriptions
    Gql::Subscriptions::User::Current::TaskbarItemUpdates.trigger_after_destroy(self)
  end

  def trigger_taskbar_item_state_update_subscriptions
    return true if !saved_change_to_attribute?('state')
    return true if !app.eql?('desktop')
    return true if destroyed?

    Gql::Subscriptions::User::Current::TaskbarItemStateUpdates.trigger(
      nil,
      arguments: {
        taskbar_item_id: Gql::ZammadSchema.id_from_internal_id('Taskbar', id),
      }
    )
  end
end
