# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class KnowledgeBase::Answer < BaseQuery
    include Gql::Concerns::HandlesKnowledgeBaseLocale

    description 'Fetch a single knowledge base answer'

    argument :answer_id, GraphQL::Types::ID, loads: Gql::Types::KnowledgeBase::AnswerType, description: 'Answer to open'
    argument :locale, String, required: false, description: 'System locale code used to resolve titles'

    type Gql::Types::KnowledgeBase::AnswerType, null: false

    def resolve(answer:, locale: nil)
      resolve_browsable_knowledge_base_answer(answer, locale)
    end
  end
end
