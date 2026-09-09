# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Add < BaseMutation
    description 'Add a new user.'

    argument :input, Gql::Types::Input::UserInputType, description: 'The user data'
    argument :send_invite, Boolean, description: 'Wether invitation is sent to the new user', required: false

    field :user, Gql::Types::UserType, description: 'The created user.'

    requires_permission 'ticket.agent', 'admin.user'

    def resolve(input:, send_invite: false)
      user_data = Gql::Types::Input::UserInputType.merge_object_attribute_values!(input.to_h)

      user = Service::User::AddInternal
        .with_current_user(context.current_user)
        .execute(user_data:, send_invite:)

      { user: }
    end
  end
end
