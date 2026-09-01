# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class KnowledgeBase::Answer::Delete < KnowledgeBase::Base
    description 'Delete a knowledge base answer.'

    argument :answer_id, GraphQL::Types::ID, loads: Gql::Types::KnowledgeBase::AnswerType, loads_pundit_method: :destroy?, description: 'Answer to delete.'

    field :success, Boolean, description: 'Was the mutation successful?'

    # No service behind this one: the argument's `destroy?` gate has already authorized the record,
    #   which leaves a single `destroy!` — there is nothing for a service to hold.
    #
    # Unlike a category, an answer has no restricted dependents, so there is no refusal path to
    #   translate into a user error: its translations and their content cascade through
    #   HasTranslations, the attachments are removed by `attachments_cleanup!`, and open taskbar
    #   tabs by HasTaskbars#destroy_taskbars.
    def resolve(answer:)
      # Deleting is editing knowledge base content, so it follows the same rule as the write
      #   services: only an active knowledge base is editable.
      ::KnowledgeBase.active.first!

      answer.destroy!

      { success: true }
    end
  end
end
