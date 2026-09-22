# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::ContentTranslationAuto < BaseMutation
    description 'Remember whether the current user reads whole tickets in their target language'

    argument :enabled, Boolean, description: 'Whether the articles of a ticket are translated on opening it'

    field :success, Boolean, null: false, description: 'Was the update successful?'

    # Translating is an agent action; the preference is nothing without it.
    requires_permission 'ticket.agent'

    def resolve(enabled:)
      Service::User::ContentTranslationAuto
        .with_current_user(context.current_user)
        .execute(enabled:)

      { success: true }
    end
  end
end
