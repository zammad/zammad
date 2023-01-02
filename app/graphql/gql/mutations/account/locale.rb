# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Account::Locale < BaseMutation
    description 'Update the language of the currently logged in user'

    argument :locale, String, 'The locale to use, e.g. "de-de".'

    field :success, Boolean, null: false, description: 'Was the update successful?'

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
