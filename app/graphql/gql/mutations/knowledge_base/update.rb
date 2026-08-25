# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class KnowledgeBase::Update < KnowledgeBase::Base
    include Gql::Concerns::HandlesKnowledgeBaseLocale

    description 'Update the knowledge base.'

    argument :input, Gql::Types::Input::KnowledgeBase::InputType, description: 'The knowledge base data.'

    # Deliberately a flat argument rather than part of `input`, which is the knowledge base's *data*:
    #   this is the locale of the call itself — the texts in the input are written into it, and the
    #   response is rendered in it. The browse queries take the same flat `locale`.
    argument :locale, String, description: 'System locale code the submitted texts belong to, and the returned knowledge base is localized in.'

    field :knowledge_base, Gql::Types::KnowledgeBaseType, null: true, description: 'The updated knowledge base.'

    def resolve(input:, locale:)
      updated = Service::KnowledgeBase::Update
        .with_current_user(context.current_user)
        .execute(knowledge_base_data: input.to_h, kb_locale: locale)

      # The locale the payload is rendered in, which the service just wrote the texts into: it
      #   rejects one the knowledge base does not have, so this resolves to that very locale.
      store_knowledge_base_locale(updated, locale)

      { knowledge_base: updated }
    rescue Exceptions::UnprocessableContent => e
      error_response({ message: e.message })
    rescue Exceptions::InvalidAttribute => e
      error_response({ message: e.message, field: e.attribute })
    end
  end
end
