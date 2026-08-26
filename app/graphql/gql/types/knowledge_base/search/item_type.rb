# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase
  class Search::ItemType < Gql::Types::BaseUnion
    graphql_name 'KnowledgeBaseSearchItem'

    description 'Object found by a knowledge base search'

    # The knowledge base node itself is not searched, see Service::KnowledgeBase::Search.
    #   BaseUnion.resolve_type maps both of these to their type by class name already.
    possible_types Gql::Types::KnowledgeBase::AnswerType, Gql::Types::KnowledgeBase::CategoryType
  end
end
