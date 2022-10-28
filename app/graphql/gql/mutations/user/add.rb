# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Add < BaseMutation
    description 'Add a new user.'

    argument :input, Gql::Types::Input::UserInputType, description: 'The user data'

    field :user, Gql::Types::UserType, description: 'The created user.'

    def self.authorize(_obj, ctx)
      ctx[:current_user].permissions?(['admin.user', 'ticket.agent'])
    end

    def resolve(input:)
      { user: add(input) }
    end

    private

    def add(input)
      user_data = input.to_h

      execute_service(::User::AddInternalService, user_data: user_data)
    end
  end
end
