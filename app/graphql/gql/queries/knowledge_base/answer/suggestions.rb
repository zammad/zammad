# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class KnowledgeBase::Answer::Suggestions < BaseQuery
    description 'Suggestions for insertable knowledge base answers in a new ticket article'

    argument :query, String, description: 'Answers to search for'

    type [Gql::Types::KnowledgeBase::Answer::TranslationType], null: true

    requires_permission 'ticket.agent'

    def resolve(query:)
      results = SearchKnowledgeBaseBackend.new(
        knowledge_base:    nil,
        locale:            nil,
        scope:             nil,
        flavor:            'agent',
        index:             'KnowledgeBase::Answer::Translation',
        highlight_enabled: false,
      ).search(query, user: context.current_user)

      ids = results.pluck(:id)

      # Load all hits in a single query with the associations the type resolves.
      #   in_order_of preserves the search (relevance) order and drops hits whose
      #   record no longer exists (stale search index).
      ::KnowledgeBase::Answer::Translation
        .includes(:content, answer: :category, kb_locale: :system_locale)
        .in_order_of(:id, ids)
    end
  end
end
