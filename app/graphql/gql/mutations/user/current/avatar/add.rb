# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::Avatar::Add < BaseMutation
    description 'Add a new avatar for the currently logged in user.'

    argument :images, Gql::Types::Input::AvatarInputType, description: 'Images to be uploaded.'

    field :avatar, Gql::Types::AvatarType, description: 'The newly created avatar.'

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('user_preferences.avatar')
    end

    def resolve(images:)
      original = images[:original]
      resized  = images[:resized]

      if original[:error].present? || resized[:error].present?
        return error_response({ message: original[:message] || resized[:message] })
      end

      { avatar: add(original, resized) }
    end

    private

    def add(original, resized)
      Service::Avatar::Add.new(current_user: context.current_user).execute(full_image: original, resize_image: resized)
    end
  end
end
