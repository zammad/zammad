# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::ContentTranslationExcludedLanguages < BaseMutation
    description 'Remember the languages the current user reads in the original when whole tickets are translated'

    argument :languages, [String], description: 'Languages without region, e.g. "en"; Chinese and Serbian with their writing system, e.g. "zh-Hant"'

    field :success, Boolean, null: false, description: 'Was the update successful?'

    # Translating is an agent action; the preference is nothing without it.
    requires_permission 'ticket.agent'

    def resolve(languages:)
      Service::User::ContentTranslationExcludedLanguages
        .with_current_user(context.current_user)
        .execute(languages:)

      { success: true }
    end
  end
end
