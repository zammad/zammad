# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class AutocompleteSearch::SnipeitModels < BaseQuery

    description 'Search for Snipe-IT models'

    argument :input, Gql::Types::Input::AutocompleteSearch::SnipeitModelsInputType, required: true, description: 'The input object for the autocomplete search'

    type [Gql::Types::AutocompleteSearch::EntryType], null: false

    requires_permission 'ticket.agent'
    requires_enabled_setting 'snipeit_integration', error_message: __('Snipe-IT integration is not enabled')

    def resolve(input:)
      api_call(input).map do |model|
        { value: model['id'].to_s, label: model['name'] }
      end
    end

    private

    # Snipe-IT filters server-side, so the search term must be passed on instead of
    # fetching a page of models and filtering it in Ruby, which would make models
    # beyond the fetched page unreachable.
    def api_call(input)
      response = Snipeit.query('models', build_params(input))
      response.is_a?(Hash) && response['rows'].is_a?(Array) ? response['rows'] : []
    rescue => e
      Rails.logger.error "Failed to fetch Snipe-IT models: #{e.message}"
      []
    end

    def build_params(input)
      params = { 'limit' => input.limit || 10 }

      # Snipe-IT models belong to a category, so a selected category can narrow the list
      # down instead of offering models which cannot hold the wanted assets.
      params['category_id'] = input.category_id if input.category_id.present?

      search = normalize_query(input.query)
      params['search'] = search if search.present?

      params
    end

    def normalize_query(query)
      query = query.strip
      return '' if query.blank? || query == '*'

      query.delete_prefix('*').delete_suffix('*')
    end
  end
end
