# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class AutocompleteSearch::SnipeitCategories < BaseQuery

    description 'Search for Snipe-IT categories'

    argument :input, Gql::Types::Input::AutocompleteSearch::InputType, required: true, description: 'The input object for the autocomplete search'

    type [Gql::Types::AutocompleteSearch::EntryType], null: false

    def self.authorize(_obj, ctx)
      Setting.get('snipeit_integration') && ctx.current_user.permissions?('ticket.agent')
    end

    def resolve(input:)
      filtered_results(input).first(input.limit || 10)&.map do |category|
        { value: category['id'].to_s, label: category['name'] }
      end
    end

    private

    def api_call
      response = Snipeit.query('categories', { limit: 500 })
      response.is_a?(Hash) && response['rows'].is_a?(Array) ? response['rows'] : []
    rescue => e
      Rails.logger.error "Failed to fetch Snipe-IT categories: #{e.message}"
      []
    end

    def filtered_results(input)
      filter = normalize_query(input.query)
      results = api_call

      return results if filter.blank?

      results.select { |result| result['name'].downcase.include?(filter) }
    end

    def normalize_query(query)
      return '' if query == '*'

      query.downcase.delete_prefix('*').delete_suffix('*')
    end
  end
end
