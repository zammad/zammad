# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum::KnowledgeBase
  # Which kind of content a knowledge base search looks for. One search returns one kind, because
  #   the result list is split by kind and each list pages on its own.
  #
  # Singular, naming one hit rather than the tab that lists it — the same vocabulary
  #   Gql::Types::Enum::SearchableModelsType uses for the global search. The knowledge base node
  #   itself is deliberately not among them, see Service::KnowledgeBase::Search.
  class SearchEntityType < Gql::Types::Enum::BaseEnum
    description 'Kind of knowledge base content to search for'

    value 'answer', 'Answers, matched in their title, body, attachments and tags.', value: :answer
    value 'category', 'Categories, matched in their title.', value: :category
  end
end
