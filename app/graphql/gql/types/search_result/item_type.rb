# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class SearchResult::ItemType < BaseUnion
    description 'Objects found by search'

    SEARCHABLE_MODELS = [::Ticket, ::User, ::Organization].freeze

    # TODO: static list for now. Change this to Models.searchable when there is full support from GraphQL types.
    def self.searchable_models
      @searchable_models ||= (SEARCHABLE_MODELS + extensions.flat_map(&:models)).freeze
    end

    possible_types(*searchable_models.map { |model| "Gql::Types::#{model.name}Type".constantize })
  end
end
