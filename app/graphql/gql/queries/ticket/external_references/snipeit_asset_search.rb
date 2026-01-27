# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket::ExternalReferences::SnipeitAssetSearch < BaseQuery

    description 'Search for Snipe-IT assets'

    argument :category_id, String, required: false, description: 'Selected Snipe-IT category id to search in'
    argument :model_id, String, required: false, description: 'Selected Snipe-IT model id to search in'
    argument :query, String, required: false, description: 'Query for searching the Snipe-IT assets'
    argument :limit, Integer, required: false, description: 'Limit for the amount of entries'

    type [Gql::Types::Ticket::ExternalReferences::SnipeitAssetType], null: false

    def self.authorize(_obj, ctx)
      Setting.get('snipeit_integration') && ctx.current_user.permissions?('ticket.agent')
    end

    def resolve(query: '', limit: 10, category_id: nil, model_id: nil)
      params = build_params(category_id:, model_id:, query:, limit:)
      response = Snipeit.query('hardware', params)

      return [] if !response.is_a?(Hash) || !response['rows'].is_a?(Array)

      response['rows'].map { |asset| normalize_asset(asset) }
    end

    private

    def build_params(category_id:, model_id:, query:, limit:)
      {}.tap do |params|
        params['limit'] = limit if limit
        params['category_id'] = category_id if category_id.present?
        params['model_id'] = model_id if model_id.present?

        search_query = normalize_query(query)
        params['search'] = search_query if search_query.present?
      end
    end

    def normalize_query(query)
      query = query.strip
      return '' if query.blank? || query == '*'

      query.delete_prefix('*').delete_suffix('*')
    end

    def normalize_asset(asset)
      {
        'id'            => asset['id'],
        'name'          => asset['name'] || asset['asset_tag'],
        'asset_tag'     => asset['asset_tag'],
        'serial'        => asset['serial'],
        'link'          => asset['link'],
        'model_name'    => asset.dig('model', 'name'),
        'status_name'   => asset.dig('status_label', 'name'),
        'category_name' => asset.dig('category', 'name'),
        'location_name' => asset.dig('location', 'name'),
      }
    end
  end
end
