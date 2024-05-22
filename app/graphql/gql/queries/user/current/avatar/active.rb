# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class User::Current::Avatar::Active < BaseQuery

    description 'Fetch actively used avatar of the currently logged-in user.'

    type Gql::Types::AvatarType, null: true

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('user_preferences.avatar')
    end

    def resolve(...)
      return if context.current_user.image.blank?

      Avatar.find_by(
        object_lookup_id: ObjectLookup.by_name('User'),
        o_id:             context.current_user.id,
        store_hash:       context.current_user.image,
      )
    end
  end
end
