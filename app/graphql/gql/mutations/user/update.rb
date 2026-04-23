# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Update < BaseMutation
    description 'Update an existing user.'

    argument :id, GraphQL::Types::ID, description: 'The user ID', as: :user, loads: Gql::Types::UserType, loads_pundit_method: :update?
    argument :input, Gql::Types::Input::UserInputType, description: 'The user data'

    field :user, Gql::Types::UserType, description: 'The updated user.'

    def resolve(user:, input:)
      { user: update(user, input) }
    end

    private

    def update(user, input)
      user_data = input.to_h

      set_core_workflow_information(user_data, ::User, 'edit')
      Service::User::FilterPermissionAssignments.with_current_user(context.current_user).execute(user_data: user_data)

      user.with_lock do
        user.update!(user_data)
      end

      user
    end
  end
end
