# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class PushMessages < BaseSubscription

    description 'Broadcast messages to all users'

    broadcastable true

    field :title, String, description: 'Message title'
    field :text, String, description: 'Message text'

    allow_public_access!

    def update
      object
    end
  end
end
