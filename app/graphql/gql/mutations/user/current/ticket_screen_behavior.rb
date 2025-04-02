# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::TicketScreenBehavior < BaseMutation
    description 'Update user ticket screen behavior settings'

    argument :behavior, Gql::Types::Enum::TicketScreenBehaviorType, description: 'Ticket screen behavior to set'

    field :success, Boolean, null: false, description: 'Whether the user ticket screen behavior setting was updated successfully'

    def resolve(behavior:)
      user = context.current_user
      user.preferences['secondaryAction'] = behavior
      user.save!

      { success: true }
    end
  end
end
