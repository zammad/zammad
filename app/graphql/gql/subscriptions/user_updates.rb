# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class UserUpdates < BaseSubscription
    description 'Updates to user records'

    include Gql::Subscriptions::Concerns::CanInitialResult

    unique_argument_id_key 'userId'

    argument :user_id, GraphQL::Types::ID, loads: Gql::Types::UserType, description: 'ID of the user to receive updates for'

    field :user, Gql::Types::UserType, description: 'Updated user'

    def subscribe(user:, initial:)
      return {} if !initial

      { user: }
    end

    def update(user:, initial:)
      { user: object }
    end
  end
end
