# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket::Article::TranslationTargetLocales < BaseQuery

    description 'Locales a ticket article can be translated into with the configured translation service'

    type [Gql::Types::LocaleType, { null: false }], null: false

    requires_permission 'ticket.agent'
    requires_enabled_setting 'content_translation_ticket_article', error_message: __('Ticket article translation is not enabled.')

    def resolve
      Service::ContentTranslation::TargetLocales.execute
    end
  end
end
