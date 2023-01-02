# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Account::Avatar::Delete < BaseMutation
    description 'Delete an existing avatar for the currently logged in user.'

    argument :id, GraphQL::Types::ID, description: 'The unique identifier of the avatar which should be deleted.'

    field :success, Boolean, null: false, description: 'Was the avatar deletion successful?'

    def resolve(id:)
      avatar_id = Gql::ZammadSchema.verified_object_from_id(id, type: Avatar).id
      if avatar_id.blank? || Avatar.find_by(id: avatar_id, o_id: context.current_user.id).blank?
        raise ActiveRecord::RecordNotFound, __('Avatar could not be found.')
      end

      Avatar.remove_one('User', context.current_user.id, avatar_id)

      set_default_avatar

      { success: true }
    end

    private

    def set_default_avatar
      Avatar.find_by(
        object_lookup_id: ObjectLookup.by_name('User'),
        o_id:             context.current_user.id,
        initial:          true,
      )&.update!(default: true)

      context.current_user.update!(image: nil)
    end
  end
end
