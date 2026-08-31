# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket::ExternalReferences::SnipeitAssetList < BaseQuery

    description 'Detailed Snipe-IT assets for the given asset ids or the given ticket'

    argument :input, Gql::Types::Input::Ticket::ExternalReferences::SnipeitAssetListInputType, description: 'The input to fetch detailed Snipe-IT assets for the given asset ids or the given ticket'

    type [Gql::Types::Ticket::ExternalReferences::SnipeitAssetType], null: false

    requires_permission 'ticket.agent'
    requires_enabled_setting 'snipeit_integration', error_message: __('Snipe-IT integration is not enabled')

    def resolve(input:)
      snipeit_asset_ids = if input.ticket.present?
                            input.ticket.preferences.dig(:snipeit, :asset_ids) || []
                          else
                            input.snipeit_asset_ids
                          end

      return [] if snipeit_asset_ids.blank?

      # Snipe-IT offers no bulk lookup by id, so assets are fetched one by one.
      # Like the i-doit integration, items which are not found are silently skipped.
      snipeit_asset_ids.filter_map { |asset_id| fetch_asset(asset_id) }
    end

    private

    def fetch_asset(asset_id)
      response = Snipeit.asset(asset_id)
      return if response.blank?

      Snipeit.normalize_asset(response)
    rescue => e
      Rails.logger.error "Failed to fetch Snipe-IT asset #{asset_id}: #{e.message}"
      nil
    end
  end
end
