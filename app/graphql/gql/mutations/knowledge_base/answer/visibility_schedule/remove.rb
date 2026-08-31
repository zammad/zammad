# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class KnowledgeBase::Answer::VisibilitySchedule::Remove < KnowledgeBase::Base
    include Gql::Concerns::HandlesKnowledgeBaseLocale

    description 'Clear a scheduled visibility change of a knowledge base answer.'

    argument :answer_id, GraphQL::Types::ID, loads: Gql::Types::KnowledgeBase::AnswerType, loads_pundit_method: :update?, description: 'Answer to clear the schedule of.'

    # Which schedule to clear is the whole request - a publication state belongs to the answer rather
    #   than to one of its translations, so there is no locale to go with it either.
    argument :visibility, Gql::Types::Enum::KnowledgeBase::SchedulableVisibilityType, description: 'Publication state whose scheduled change is to be cleared.'

    field :answer, Gql::Types::KnowledgeBase::AnswerType, null: true, description: 'The answer with its updated schedule.'

    def resolve(answer:, visibility:)
      updated = Service::KnowledgeBase::Answer::VisibilitySchedule::Remove
        .with_current_user(context.current_user)
        .execute(answer:, visibility:)

      # No locale is asked of the caller, but the answer that is rendered back has locale-dependent
      #   fields all the same - so the payload is localized the way every knowledge base read without
      #   an explicit locale is: in the current user's preferred one
      #   (Gql::Concerns::HandlesKnowledgeBaseLocale#resolve_knowledge_base_locale).
      store_knowledge_base_locale(updated.category.knowledge_base, nil)

      { answer: updated }
    rescue Exceptions::UnprocessableContent => e
      error_response({ message: e.message })
    end
  end
end
