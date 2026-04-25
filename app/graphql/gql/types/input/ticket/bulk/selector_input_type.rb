# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Ticket
  class Bulk::SelectorInputType < Gql::Types::BaseInputObject
    description 'Represents the selector for bulk ticket update.'

    argument :entity_ids, [GraphQL::Types::ID], required: false, description: 'The tickets to be updated'
    argument :overview_id, GraphQL::Types::ID, required: false, loads: Gql::Types::OverviewType, description: 'Ticket overview for selecting tickets'
    argument :search_query, String, required: false, description: 'Search query to filter tickets'

    def prepare
      hash = to_h

      if !hash.slice(:entity_ids, :overview, :search_query).values.one?(&:present?)
        raise GraphQL::ExecutionError, 'Exactly one of entity_ids, overview_id, or search_query must be provided.' # rubocop:disable Zammad/DetectTranslatableString
      end

      if hash[:entity_ids].try(:any?)
        hash[:entity_ids] = Gql::ZammadSchema.internal_ids_from_ids(entity_ids, type: ::Ticket)
      end

      hash
    end
  end
end
