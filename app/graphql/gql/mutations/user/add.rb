# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Add < BaseMutation
    description 'Add a new user.'

    argument :input, Gql::Types::Input::UserInputType, description: 'The user data'
    argument :send_invite, Boolean, description: 'Wether invitation is sent to the new user', required: false

    field :user, Gql::Types::UserType, description: 'The created user.'

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?(['admin.user', 'ticket.agent'])
    end

    def resolve(input:, send_invite: false)
      user = Service::User::AddInternal
        .new(current_user: context.current_user)
        .execute(user_data: input.to_h, send_invite:)

      { user: }
    end
  end
end
