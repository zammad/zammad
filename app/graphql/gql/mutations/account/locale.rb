# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Account::Locale < BaseMutation
    description 'Update the language of the currently logged in user'

    argument :locale_id, GraphQL::Types::ID, 'Locale ID.'

    field :success, Boolean, null: false, description: 'Was the update successful?'

    def resolve(locale_id:)
      locale = Gql::ZammadSchema.object_from_id(locale_id, only: [Locale])
      if !locale&.active
        raise ActiveRecord::RecordNotFound, __('Locale could not be found.')
      end

      context.current_user.preferences['locale'] = locale.locale
      context.current_user.save!
      { success: true }
    end

  end
end
