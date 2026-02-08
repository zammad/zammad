# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::Locale < BaseMutation
    description 'Update the language of the currently logged in user'

    argument :locale, String, 'The locale to use, e.g. "de-de".'

    field :success, Boolean, null: false, description: 'Was the update successful?'

    requires_permission 'user_preferences.language'

    def resolve(locale:)
      if !Locale.exists?(locale: locale, active: true)
        raise ActiveRecord::RecordNotFound, __('Locale could not be found.')
      end

      context.current_user.preferences['locale'] = locale
      context.current_user.save!
      { success: true }
    end

  end
end
