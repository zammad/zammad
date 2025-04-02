# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket::ExternalReferences::IdoitObjectSearch < BaseQuery

    description 'Search for idoit objects belonging to a selected type'

    argument :idoit_type_id, String, required: false, description: 'Selected idoit object type id to search in'
    argument :query, String, required: false, description: 'Query for searching the idoit objects'
    argument :limit, Integer, required: false, description: 'Limit for the amount of entries'

    type [Gql::Types::Ticket::ExternalReferences::IdoitObjectType], null: false

    def self.authorize(_obj, ctx)
      Setting.get('idoit_integration') && ctx.current_user.permissions?('ticket.agent')
    end

    def resolve(query: '', limit: 10, idoit_type_id: nil)
      Idoit.query('cmdb.objects', build_filter(idoit_type_id:, query:))['result']&.first(limit)
    end

    private

    def build_filter(idoit_type_id:, query:)
      {}.tap do |filter|
        if idoit_type_id
          filter['type'] = idoit_type_id
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
