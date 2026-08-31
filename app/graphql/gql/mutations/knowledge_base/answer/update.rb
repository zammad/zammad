# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class KnowledgeBase::Answer::Update < KnowledgeBase::Base
    include Gql::Concerns::HandlesKnowledgeBaseLocale

    description 'Update a knowledge base answer.'

    argument :answer_id, GraphQL::Types::ID, loads: Gql::Types::KnowledgeBase::AnswerType, loads_pundit_method: :update?, description: 'Answer to update.'

    # The category rides inside the input, deliberately ungated there: the form sends the stored
    #   category back on every save, and only an actual move is authorized against the target, which
    #   the service does.
    argument :input, Gql::Types::Input::KnowledgeBase::UpdateAnswerInputType, description: 'The answer data. Every attribute is optional; an absent one leaves the stored value alone.'

    # Deliberately a flat argument rather than part of `input`, which is the answer's *data*: this
    #   is the locale of the call itself — the title and body in the input are written into it, and
    #   the response is rendered in it. The browse queries take the same flat `locale`.
    argument :locale, String, description: 'System locale code the submitted title and body are written into, and the returned answer is localized in.'

    # How to carry out the save, as opposed to what to store - the form's starting point for the
    #   concurrency check, and the exceptions the caller chooses to override.
    #
    # rubocop:disable GraphQL/ExtractInputType -- what the cop asks for is already here: the answer's
    #   data is in `input` and the call's own options are in `meta`. It counts four arguments only
    #   because `locale` is deliberately flat, for the reason given above.
    argument :meta, Gql::Types::Input::KnowledgeBase::Answer::UpdateMetaInputType, required: false, description: 'How to carry out the update.'
    # rubocop:enable GraphQL/ExtractInputType

    field :answer, Gql::Types::KnowledgeBase::AnswerType, null: true, description: 'The updated answer.'

    def resolve(answer:, input:, locale:, meta: nil)
      answer_data = input.to_h.merge(known_attachments: meta&.dig(:known_attachments))

      updated = Service::KnowledgeBase::Answer::Update
        .with_current_user(context.current_user)
        .execute(answer:, answer_data:, kb_locale: locale, skip_validators: meta&.dig(:skip_validators))

      # The locale the payload is rendered in, which the service just wrote the title and body into:
      #   its locale-dependent fields go straight into the client cache, so they must speak the
      #   locale that was written. The service rejects a locale the knowledge base does not have, so
      #   this resolves to that very locale.
      store_knowledge_base_locale(updated.category.knowledge_base, locale)

      { answer: updated }
    rescue Exceptions::UnprocessableContent => e
      error_response({ message: e.message })
    rescue Exceptions::InvalidAttribute => e
      error_response({ message: e.message, field: e.attribute })
    rescue Service::KnowledgeBase::Answer::Update::Validator::BaseError => e
      # The exception class travels with the error, so the client can tell this apart from a plain
      #   failure and offer to resubmit it in `skipValidators`.
      error_response({ message: e.message, exception: e.class })
    end
  end
end
