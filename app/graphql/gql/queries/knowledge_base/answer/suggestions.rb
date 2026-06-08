# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class KnowledgeBase::Answer::Suggestions < BaseQuery
    description 'Suggestions for insertable knowledge base answers in a new ticket article'

    argument :query, String, description: 'Answers to search for'

    type [Gql::Types::KnowledgeBase::Answer::TranslationType], null: true

    requires_permission 'ticket.agent'

    def resolve(query:)
      SearchKnowledgeBaseBackend.new(
        knowledge_base:    nil,
        locale:            nil,
        scope:             nil,
        flavor:            'agent',
        index:             'KnowledgeBase::Answer::Translation',
        highlight_enabled: false,
      ).search(query, user: context.current_user).map { |meta| ::KnowledgeBase::Answer::Translation.find(meta[:id]) }
    end
  end
end
