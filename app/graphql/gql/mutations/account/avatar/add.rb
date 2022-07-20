# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Account::Avatar::Add < BaseMutation
    description 'Add a new avatar for the currently logged in user.'

    argument :images, Gql::Types::Input::AvatarInputType, required: true, description: 'Images to be uploaded.'

    field :avatar, Gql::Types::AvatarType, null: true, description: 'The newly created avatar.'

    def resolve(images:)
      file_full   = images[:full]
      file_resize = images[:resize]

      if file_full[:error_message].present? || file_resize[:error_message].present?
        return error_response({
                                message: file_full[:error_message] || file_resize[:error_message]
                              })
      end

      { avatar: store_avatar(file_full, file_resize) }
    end

    private

    def store_avatar(file_full, file_resize)
      avatar = Avatar.add(
        object:    'User',
        o_id:      context.current_user.id,
        full:      {
          content:   file_full[:content],
          mime_type: file_full[:mime_type],
        },
        resize:    {
          content:   file_resize[:content],
          mime_type: file_resize[:mime_type],
        },
        source:    "upload #{Time.zone.now}",
        deletable: true,
      )

      context.current_user.update!(image: avatar.store_hash)

      avatar
    end
  end
end
