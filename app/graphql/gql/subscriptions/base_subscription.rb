# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Gql::Subscriptions
  class BaseSubscription < GraphQL::Schema::Subscription
    include Gql::Concern::HandlesAuthorization

    object_class Gql::Types::BaseObject
    field_class Gql::Types::BaseField
    argument_class Gql::Types::BaseArgument

    #
    # Default subscribe implementation that returns nothing. For this to work, all fields must have null: true.
    # Otherwise, you can provide a subscribe method in the inheriting class.
    #
    def subscribe
      {}
    end

    def no_update
      # Documentation suggests to cancel updates via 'NO_UPDATE', which does not seem to work:
      # NameError: uninitialized constant GraphQL::Schema::Subscription::NO_UPDATE
      :no_update
    end
  end
end
