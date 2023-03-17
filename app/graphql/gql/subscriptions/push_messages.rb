# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class PushMessages < BaseSubscription

    description 'Broadcast messages to all users'

    broadcastable true

    field :title, String, description: 'Message title'
    field :text, String, description: 'Message text'

    def self.authorize(...)
      true # This subscription should be available for all (including unauthenticated) users.
    end

    def update
      object
    end
  end
end
