# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::Appearance < BaseMutation
    description 'Update user profile appearance settings'

    argument :theme, Gql::Types::Enum::AppearanceThemeType, description: 'Theme to set'

    field :success, Boolean, null: false, description: 'Profile appearance settings updated successfully?'

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('user_preferences.appearance')
    end

    def resolve(theme:)
      user = context.current_user
      user.preferences['theme'] = theme
      user.save!

      { success: true }
    end
  end
end
