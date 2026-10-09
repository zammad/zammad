# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::User
  class PushSubscriptionKeysInputType < Gql::Types::BaseInputObject
    description 'Client keys of a web push subscription (PushSubscription.toJSON().keys)'

    argument :p256dh, String, 'Public key of the client, base64url encoded'
    argument :auth,   String, 'Authentication secret of the client, base64url encoded'
  end
end
