# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class KnowledgeBase::Answer::VisibilitySchedule::Add < KnowledgeBase::Base
    include Gql::Concerns::HandlesKnowledgeBaseLocale

    description 'Schedule a visibility change of a knowledge base answer.'

    argument :answer_id, GraphQL::Types::ID, loads: Gql::Types::KnowledgeBase::AnswerType, loads_pundit_method: :update?, description: 'Answer to schedule the change for.'

    # Flat arguments rather than an input type: a publication state belongs to the answer, not to one
    #   of its translations, so there is no locale to go with them - which leaves the two attributes
    #   of the change itself, the same shape as the tag assignment mutations.
    argument :visibility, Gql::Types::Enum::KnowledgeBase::SchedulableVisibilityType, description: 'Publication state the answer is to reach. Replaces the change this state is already scheduled for, if any.'
    argument :scheduled_at, GraphQL::Types::ISO8601DateTime, description: 'When the answer is to reach that state. Must be in the future.'

    field :answer, Gql::Types::KnowledgeBase::AnswerType, null: true, description: 'The answer with its updated schedule.'

    def resolve(answer:, visibility:, scheduled_at:)
      updated = Service::KnowledgeBase::Answer::VisibilitySchedule::Add
        .with_current_user(context.current_user)
        .execute(answer:, visibility:, scheduled_at:)

      # No locale is asked of the caller, but the answer that is rendered back has locale-dependent
      #   fields all the same - so the payload is localized the way every knowledge base read without
      #   an explicit locale is: in the current user's preferred one
      #   (Gql::Concerns::HandlesKnowledgeBaseLocale#resolve_knowledge_base_locale).
      store_knowledge_base_locale(updated.category.knowledge_base, nil)

      { answer: updated }
    rescue Exceptions::UnprocessableContent => e
      error_response({ message: e.message })
    rescue Exceptions::InvalidAttribute => e
      # The name of the argument that has to change, which is what the flyout's fields are called -
      #   so the complaint lands on the state or the date rather than at the top of the form.
      error_response({ message: e.message, field: e.attribute })
    end
  end
end
