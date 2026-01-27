# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket::ExternalReferences::SnipeitAssetList < BaseQuery

    description 'Detailed Snipe-IT assets for the given asset ids or the given ticket'

    argument :input, Gql::Types::Input::Ticket::ExternalReferences::SnipeitAssetListInputType, description: 'The input to fetch detailed Snipe-IT assets for the given asset ids or the given ticket'

    type [Gql::Types::Ticket::ExternalReferences::SnipeitAssetType], null: false

    def self.authorize(_obj, ctx)
      Setting.get('snipeit_integration') && ctx.current_user.permissions?('ticket.agent')
    end

    def resolve(input:)
      snipeit_asset_ids = if input.ticket.present?
                            input.ticket.preferences.dig(:snipeit, :asset_ids) || []
                          else
                            input.snipeit_asset_ids
                          end

      return [] if snipeit_asset_ids.blank?

      # Fetch assets one by one and normalize the response
      assets = []
      snipeit_asset_ids.each do |asset_id|
        begin
          response = Snipeit.query("hardware/#{asset_id}")
          if response.is_a?(Hash) && response['id']
            assets.push(normalize_asset(response))
          end
        rescue => e
          Rails.logger.error "Failed to fetch Snipe-IT asset #{asset_id}: #{e.message}"
          # Skip failed assets silently to match i-doit behavior
        end
      end

      assets
    end

    private

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
