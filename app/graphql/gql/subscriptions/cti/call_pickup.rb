# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class Cti::CallPickup < BaseSubscription
    description 'The view to open when the current user picks up a call of the CTI integration'

    subscription_scope :current_user_id

    requires_permission 'cti.agent+ticket.agent'

    field :target, Gql::Types::Cti::PickupTargetType, null: true, description: 'The view to open, resolved on the server'

    # Resolved by Cti::Driver::Base when the call is answered, and passed through as is.
    def update
      { target: object }
    end
  end
end
