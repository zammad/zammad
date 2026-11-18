# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket::ExternalReferences::IdoitUpObjectSearch < BaseQuery

    description 'Search for i-doit up objects belonging to a selected type'

    argument :idoit_up_type_id, String, required: false, description: 'Selected i-doit up object type id to search in'
    argument :query, String, required: false, description: 'Query for searching the i-doit up objects'
    argument :limit, Integer, required: false, description: 'Limit for the amount of entries'

    type [Gql::Types::Ticket::ExternalReferences::IdoitUpObjectType], null: false

    requires_permission 'ticket.agent'
    requires_enabled_setting 'idoit_up_integration', error_message: __('i-doit up integration is not enabled')

    def resolve(query: '', limit: 10, idoit_up_type_id: nil)
      IdoitUp.query('cmdb.objects', build_filter(idoit_up_type_id:, query:), user: context.current_user)['result']&.first(limit)
    end

    private

    def build_filter(idoit_up_type_id:, query:)
      {}.tap do |filter|
        if idoit_up_type_id
          filter['type'] = idoit_up_type_id
        end

        search_query = normalize_query(query)
        if search_query.present?
          filter['title'] = search_query
        end
      end
    end

    def normalize_query(query)
      query = query.strip
      return '' if query.blank? || query == '*'

      "%#{query.delete_prefix('*').delete_suffix('*')}%"
    end
  end
end
