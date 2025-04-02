# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::OutOfOffice < BaseMutation
    description 'Update user profile out of office settings'

    argument :input, Gql::Types::Input::OutOfOfficeInputType, description: 'Out of Office settings'

    field :success, Boolean, description: 'Profile out of office settings updated successfully?'

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('user_preferences.out_of_office+ticket.agent')
    end

    def resolve(input:)
      Service::User::OutOfOffice
        .new(context.current_user, **input)
        .execute

      { success: true }
    end
  end
end
