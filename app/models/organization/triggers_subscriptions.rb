# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# Trigger GraphQL subscriptions on user changes.
module Organization::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    after_update_commit :trigger_subscriptions
  end

  private

  def trigger_subscriptions
    Gql::Subscriptions::OrganizationUpdates.trigger(self, arguments: { organization_id: Gql::ZammadSchema.id_from_object(self) })
  end
end
