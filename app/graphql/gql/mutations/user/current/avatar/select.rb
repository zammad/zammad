# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::Avatar::Select < BaseMutation
    description 'Select avatar for the currently logged in user.'

    argument :id, GraphQL::Types::ID, description: 'The unique identifier of the avatar which should be selected.'

    field :success, Boolean, null: false, description: 'Was the avatar selection successful?'

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('user_preferences.avatar')
    end

    def resolve(id:)
      avatar_id = Gql::ZammadSchema.verified_object_from_id(id, type: Avatar).id
      if avatar_id.blank? || Avatar.find_by(id: avatar_id, o_id: context.current_user.id).blank?
        raise ActiveRecord::RecordNotFound, __('Avatar could not be found.')
      end

      avatar = Avatar.set_default('User', context.current_user.id, avatar_id)

      context.current_user.update!(image: avatar.store_hash)

      { success: true }
    end
  end
end
