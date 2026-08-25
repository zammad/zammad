# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class KnowledgeBase::Answer::Add < KnowledgeBase::Base
    include Gql::Concerns::HandlesKnowledgeBaseLocale

    description 'Create a knowledge base answer.'

    argument :input, Gql::Types::Input::KnowledgeBase::CreateAnswerInputType, description: 'The answer data.'

    # Deliberately a flat argument rather than part of `input`, which is the answer's *data*: this
    #   is the locale of the call itself — the title and body in the input are written into it, and
    #   the response is rendered in it. The browse queries take the same flat `locale`.
    argument :locale, String, description: 'System locale code the submitted title and body belong to, and the returned answer is localized in.'

    field :answer, Gql::Types::KnowledgeBase::AnswerType, null: true, description: 'The created answer.'

    # Which knowledge base the answer goes to is not asked of the client: there is only one, and the
    #   service resolves it — the same way the category mutations do.
    #
    # Where the answer may be filed is decided by AnswerPolicy#create? in the service, which asks it
    #   of the built answer — and through it of the category. The category in the input is therefore
    #   not gated here: a granular editor of one subtree is usually only a *reader* of the knowledge
    #   base itself, and that must not stand in the way of filing an answer in a category they do
    #   have editor access to.
    def resolve(input:, locale:)
      created = Service::KnowledgeBase::Answer::Create
        .with_current_user(context.current_user)
        .execute(answer_data: input.to_h, kb_locale: locale)

      # The locale the payload is rendered in, which the service just wrote the title and body into:
      #   its locale-dependent fields go straight into the client cache, so they must speak the
      #   locale that was written. The service rejects a locale the knowledge base does not have, so
      #   this resolves to that very locale.
      store_knowledge_base_locale(created.category.knowledge_base, locale)

      { answer: created }
    rescue Exceptions::UnprocessableContent => e
      error_response({ message: e.message })
    rescue Exceptions::InvalidAttribute => e
      error_response({ message: e.message, field: e.attribute })
    end
  end
end
