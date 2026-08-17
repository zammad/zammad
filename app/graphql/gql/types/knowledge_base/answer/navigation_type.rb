# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase::Answer
  class NavigationType < Gql::Types::BaseObject
    description 'Navigation between visible answers in one category'

    field :index, Integer, null: false, description: '1-based position of this answer among the visible answers of its category'
    field :total_count, Integer, null: false, description: 'Number of answers visible to the user in this answer’s category'
    field :previous_answer, Gql::Types::KnowledgeBase::AnswerType, null: false, description: 'Previous sibling; wraps to the last answer'
    field :next_answer, Gql::Types::KnowledgeBase::AnswerType, null: false, description: 'Next sibling; wraps to the first answer'

    def index
      object.fetch(:index)
    end

    def total_count
      object.fetch(:total_count)
    end

    def previous_answer
      object.fetch(:previous_answer)
    end

    def next_answer
      object.fetch(:next_answer)
    end
  end
end
