# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Account::OutOfOffice < BaseMutation
    description 'Update user profile out of office settings'

    argument :settings, Gql::Types::Input::OutOfOfficeInputType, description: 'Theme to set'

    field :success, Boolean, null: false, description: 'Profile out of office settings updated successfully?'

    def resolve(settings:)
      user = context.current_user
      user.with_lock do
        user.assign_attributes(
          out_of_office:                settings.enabled,
          out_of_office_start_at:       settings.start_at,
          out_of_office_end_at:         settings.end_at,
          out_of_office_replacement_id: settings.replacement
        )
        user.preferences[:out_of_office_text] = settings.text
        user.save!
      end

      { success: true }
    end
  end
end
