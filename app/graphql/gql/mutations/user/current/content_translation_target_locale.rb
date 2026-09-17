# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::ContentTranslationTargetLocale < BaseMutation
    description 'Remember the language the current user translates content into'

    argument :target_locale, String, description: 'The locale to translate into, e.g. "de-de".'

    field :success, Boolean, null: false, description: 'Was the update successful?'

    # Translating is an agent action; the preference is nothing without it.
    requires_permission 'ticket.agent'

    def resolve(target_locale:)
      Service::User::ContentTranslationTargetLocale
        .with_current_user(context.current_user)
        .execute(target_locale:)

      { success: true }
    end
  end
end
