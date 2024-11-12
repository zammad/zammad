# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class AutocompleteSearch::IdoitObjectTypes < BaseQuery

    description 'Search for idoit object types'

    argument :input, Gql::Types::Input::AutocompleteSearch::InputType, required: true, description: 'The input object for the autocomplete search'

    type [Gql::Types::AutocompleteSearch::EntryType], null: false

    def self.authorize(_obj, ctx)
      Setting.get('idoit_integration') && ctx.current_user.permissions?('ticket.agent')
    end

    def resolve(input:)
      filtered_results(input).first(input.limit || 10)&.map do |type|
        { value: type['id'], label: type['title'] }
      end
    end

    private

    def api_call
      Idoit.query('cmdb.object_types')['result'] || []
    end

    def filtered_results(input)
      filter = normalize_query(input.query)
      results = api_call

      return results if filter.blank?

      results.select { |result| result['title'].downcase.include?(filter) }
    end

    def normalize_query(query)
      return '' if query == '*'

      query.downcase.delete_prefix('*').delete_suffix('*')
    end
  end
end
