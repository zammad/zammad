# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum::KnowledgeBase
  class AnswerScreenType < Gql::Types::Enum::BaseEnum
    description 'The knowledge base answer screen a preference applies to'

    # The two screens that save an answer, and that are configured independently of each other:
    #   somebody adding answers in a row wants to be left on the form, while the same person
    #   editing one usually wants to stay with what they just corrected.
    value 'create', 'The view an answer is added in.'
    value 'edit', 'The view an existing answer is edited in.'
  end
end
