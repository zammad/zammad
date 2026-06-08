# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class User::Current::TaskbarItemStateUpdates < BaseSubscription

    description 'Changes to the state of a taskbar item of the currently logged-in user'

    argument :taskbar_item_id, GraphQL::Types::ID, required: true, loads: Gql::Types::User::TaskbarItemType, loads_pundit_method: :update?, description: 'The taskbar item ID'

    field :state_update_type, Gql::Types::Enum::TaskbarStateUpdateType, description: 'The type of state update'
    field :taskbar_item, Gql::Types::User::TaskbarItemType, null: true, description: 'The updated taskbar item, so consumers can apply the new state directly (e.g. cross-tab search sync)'

    def update(taskbar_item:)
      { state_update_type: object[:state_update_type], taskbar_item: }
    end
  end
end
