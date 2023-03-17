# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Account::Avatar::Add < BaseMutation
    description 'Add a new avatar for the currently logged in user.'

    argument :images, Gql::Types::Input::AvatarInputType, description: 'Images to be uploaded.'

    field :avatar, Gql::Types::AvatarType, description: 'The newly created avatar.'

    def resolve(images:)
      file_full   = images[:full]
      file_resize = images[:resize]

      if file_full[:error].present? || file_resize[:error].present?
        return error_response({ message: file_full[:message] || file_resize[:message] })
      end

      {
        avatar: Service::Avatar::Add.new(current_user: context.current_user).execute(full_image: file_full, resize_image: file_resize)
      }
    end
  end
end
