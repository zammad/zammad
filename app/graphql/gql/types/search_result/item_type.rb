# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class SearchResult::ItemType < BaseUnion
    description 'Objects found by search'

    # KnowledgeBase::Answer::Translation rather than ::KnowledgeBase::Answer: the translation is the
    #   searchable unit (it carries the title and the body that are indexed), and it is what the
    #   result list renders. It is also the one model here that Service::Search does not serve - see
    #   Gql::Concerns::SearchesKnowledgeBaseAnswers for why, and for what serves it instead.
    SEARCHABLE_MODELS = [::Ticket, ::User, ::Organization, ::KnowledgeBase::Answer::Translation].freeze

    # TODO: static list for now. Change this to Models.searchable when there is full support from GraphQL types.
    def self.searchable_models
      @searchable_models ||= (SEARCHABLE_MODELS + extensions.flat_map(&:models)).freeze
    end

    possible_types(*searchable_models.map { |model| "Gql::Types::#{model.name}Type".constantize })
  end
end
