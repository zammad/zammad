# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Ticket
  class Macros::SelectorInputType < Gql::Types::BaseInputObject
    description 'Represents the selector for ticket macros query.'

    argument :entity_ids, [GraphQL::Types::ID], required: false, description: 'The groups to be considered'
    argument :overview_id, GraphQL::Types::ID, required: false, loads: Gql::Types::OverviewType, description: 'Ticket overview for selecting tickets and their groups'
    argument :search_query, String, required: false, description: 'Search query to filter tickets and their groups'

    def prepare
      hash = to_h

      if !hash.slice(:entity_ids, :overview, :search_query).values.one?(&:present?)
        raise GraphQL::ExecutionError, 'Exactly one of entity_ids, overview_id, or search_query must be provided.' # rubocop:disable Zammad/DetectTranslatableString
      end

      if hash[:entity_ids].try(:any?)
        hash[:entity_ids] = Gql::ZammadSchema.internal_ids_from_ids(entity_ids, type: ::Group)
      end

      hash
    end
  end
end
