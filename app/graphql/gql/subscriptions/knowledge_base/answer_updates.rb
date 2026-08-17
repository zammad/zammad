# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class KnowledgeBase::AnswerUpdates < BaseSubscription
    include Gql::Concerns::HandlesKnowledgeBaseLocale
    include Gql::Subscriptions::Concerns::CanInitialResult

    description 'Updates to a single knowledge base answer'

    unique_argument_id_key 'answerId'

    argument :answer_id, GraphQL::Types::ID, loads: Gql::Types::KnowledgeBase::AnswerType, description: 'Answer identifier'
    argument :locale, String, required: false, description: 'System locale code used to resolve titles'

    field :answer, Gql::Types::KnowledgeBase::AnswerType, description: 'Updated answer'

    def subscribe(answer:, initial:, locale: nil)
      return {} if !initial

      answer = resolve_browsable_knowledge_base_answer(answer, locale)

      { answer: }
    end

    def update(answer:, initial:, locale: nil)
      resolved_answer = resolve_browsable_knowledge_base_answer(object, locale)

      { answer: resolved_answer }
    end
  end
end
