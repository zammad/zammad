# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# Trigger GraphQL subscriptions on token changes.
module Token::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    # Tokens cannot be modified after creating so no need to push updates on update
    # Meanwhile pushing on update would be triggered when last_used_at is updated which may be an overkill
    after_commit :trigger_user_subscription, on: %i[create destroy]
  end

  def trigger_user_subscription
    return if !visible_in_frontend?

    Gql::Subscriptions::User::Current::AccessTokenUpdates.trigger(
      nil,
      arguments: {
        user_id: Gql::ZammadSchema.id_from_internal_id('User', user_id)
      }
    )
  end
end
