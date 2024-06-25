# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# Trigger GraphQL subscriptions on template changes.
module Template::TriggersSubscriptions
  extend ActiveSupport::Concern

  included do
    after_commit :trigger_subscriptions
  end

  private

  def trigger_subscriptions
    Gql::Subscriptions::TemplateUpdates.trigger(nil, arguments: { only_active: false })
    Gql::Subscriptions::TemplateUpdates.trigger(nil, arguments: { only_active: true })
  end
end
