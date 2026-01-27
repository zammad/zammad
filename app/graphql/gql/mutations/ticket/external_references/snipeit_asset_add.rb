# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::ExternalReferences::SnipeitAssetAdd < BaseMutation
    description 'Add Snipe-IT assets to a ticket or just resolve them for ticket creation.'

    argument :ticket_id,         GraphQL::Types::ID, required: false, loads: Gql::Types::TicketType, loads_pundit_method: :agent_update_access?, description: 'The related ticket for the Snipe-IT assets'
    argument :snipeit_asset_ids, [Integer], description: 'The Snipe-IT assets to add'

    field :snipeit_assets, [Gql::Types::Ticket::ExternalReferences::SnipeitAssetType], description: 'The added / resolved Snipe-IT assets'

    def self.authorize(_obj, _ctx)
      Setting.get('snipeit_integration')
    end

    def authorized?(snipeit_asset_ids:, ticket: nil)
      return super if ticket.present?

      context.current_user.permissions?('ticket.agent') && super
    end

    def resolve(snipeit_asset_ids:, ticket: nil)
      results = []
      existing_ids = ticket&.preferences&.dig(:snipeit, :asset_ids) || []

      snipeit_asset_ids.each do |snipeit_asset_id|
        if existing_ids.include?(snipeit_asset_id)
          return error_response({ field: :snipeit_asset_ids, message: __('The Snipe-IT asset is already present on the ticket.') })
        end

        api_asset = Snipeit.query("hardware/#{snipeit_asset_id}")

        if !api_asset.is_a?(Hash) || !api_asset['id']
          return error_response({ field: :snipeit_asset_ids, message: __('The Snipe-IT asset could not be found.') })
        end

        results.push normalize_asset(api_asset)
      end

      if ticket.present?
        ticket.preferences[:snipeit] ||= {}
        ticket.preferences[:snipeit][:asset_ids] ||= []
        ticket.preferences[:snipeit][:asset_ids].push(*snipeit_asset_ids)
        ticket.save!
      end

      { snipeit_assets: results }
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
