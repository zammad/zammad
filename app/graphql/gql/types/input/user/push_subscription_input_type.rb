# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::User
  class PushSubscriptionInputType < Gql::Types::BaseInputObject
    description 'Web push subscription of the current browser (PushSubscription.toJSON())'

    argument :endpoint, String, 'Push service endpoint of the subscription'
    argument :keys, PushSubscriptionKeysInputType, 'Client keys of the subscription'
  end
end
