# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# Trigger GraphQL subscriptions on avatar changes.
module Avatar::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    after_update_commit :update_avatar_subscription
    after_destroy_commit :destroy_avatar_subscription
  end

  private

  def update_avatar_subscription
    return if saved_changes.blank?
    return if !saved_changes.key?('default')

    # Following logic for checking if the subscription triggering is needed is applied:
    #   If the default avatar was changed from false to true, we can skip the triggering if
    #     a) the avatar is not initial.
    #     b) there is already a default avatar that is not initial.

    if saved_changes['default'].first == false && saved_changes['default'].last == true
      return if !initial

      default_non_initial_avatar = Avatar.find_by(
        object_lookup_id:,
        o_id:,
        default:          true,
        initial:          false,
      )

      return if default_non_initial_avatar.present?
    end

    trigger_user_subscription
  end

  def destroy_avatar_subscription
    # We need to check if the default avatar was deleted.
    #   If yes, there is no need to trigger the subscription,
    #     because it will be triggered by changing the default state of the remaining avatar.
    return if default

    trigger_user_subscription
  end

  def trigger_user_subscription
    return if ObjectLookup.by_id(object_lookup_id) != 'User'

    Gql::Subscriptions::User::Current::AvatarUpdates.trigger(
      nil,
      arguments: {
        user_id: Gql::ZammadSchema.id_from_internal_id('User', o_id)
      }
    )
  end
end
