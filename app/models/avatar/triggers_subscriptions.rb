# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# Trigger GraphQL subscriptions on avatar changes.
module Avatar::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    after_update_commit :trigger_user_subscriptions
  end

  private

  def trigger_user_subscriptions
    return if ObjectLookup.by_id(object_lookup_id) != 'User'

    return if saved_changes.empty? && !new_record? && !destroyed?

    Gql::Subscriptions::AccountAvatarUpdates.trigger(
      self,
      arguments: {
        user_id: Gql::ZammadSchema.id_from_internal_id('User', o_id)
      }
    )
  end
end
