# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Update < BaseMutation
    description 'Update an existing user.'

    argument :id, GraphQL::Types::ID, description: 'The user ID', as: :current_user, loads: Gql::Types::UserType
    argument :input, Gql::Types::Input::UserInputType, description: 'The user data'

    field :user, Gql::Types::UserType, description: 'The created user.'

    def authorized?(current_user:, input:)
      Pundit.authorize(context.current_user, current_user, :update?)
    end

    def resolve(current_user:, input:)
      { user: update(current_user, input) }
    end

    private

    def update(current_user, input)
      user_data = input.to_h

      set_core_workflow_information(user_data, ::User, 'edit')
      Service::User::FilterPermissionAssignments.new(current_user: current_user).execute(user_data: user_data)

      current_user.with_lock do
        current_user.update!(user_data)
      end

      current_user
    end
  end
end
