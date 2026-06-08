# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::NoteUpdate < BaseMutation
    description 'Update the note field of a user.'

    argument :id, GraphQL::Types::ID, description: 'The user ID', as: :current_user, loads: Gql::Types::UserType, loads_pundit_method: :update?
    argument :note, String, description: 'The user note'

    field :user, Gql::Types::UserType, description: 'The created user.'

    def resolve(current_user:, note:)
      { user: forced_update(current_user:, note:) }
    end

    private

    def forced_update(current_user:, note:)
      current_user.with_lock do
        current_user.update!({ note: })
      end

      current_user
    end
  end
end
