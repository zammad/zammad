# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::ExternalReferences::SnipeitAssetAdd < BaseMutation
    description 'Add Snipe-IT assets to a ticket or just resolve them for ticket creation.'

    argument :ticket_id,         GraphQL::Types::ID, required: false, loads: Gql::Types::TicketType, loads_pundit_method: :agent_update_access?, description: 'The related ticket for the Snipe-IT assets'
    argument :snipeit_asset_ids, [Integer], description: 'The Snipe-IT assets to add'

    field :snipeit_assets, [Gql::Types::Ticket::ExternalReferences::SnipeitAssetType], description: 'The added / resolved Snipe-IT assets'

    requires_enabled_setting 'snipeit_integration', error_message: __('Snipe-IT integration is not enabled')

    def authorized?(snipeit_asset_ids:, ticket: nil)
      ticket.present? || context.current_user.permissions?('ticket.agent')
    end

    def resolve(snipeit_asset_ids:, ticket: nil)
      results = []
      existing_ids = Array(ticket&.preferences&.dig(:snipeit, :asset_ids)).map(&:to_i)
      seen_ids = existing_ids.dup

      snipeit_asset_ids.each do |snipeit_asset_id|
        snipeit_asset_id = snipeit_asset_id.to_i

        if seen_ids.include?(snipeit_asset_id)
          return error_response({ field: :snipeit_asset_ids, message: __('The Snipe-IT asset is already present on the ticket.') })
        end

        api_asset = Snipeit.asset(snipeit_asset_id)

        if api_asset.blank?
          return error_response({ field: :snipeit_asset_ids, message: __('The Snipe-IT asset could not be found.') })
        end

        seen_ids << snipeit_asset_id
        results.push Snipeit.normalize_asset(api_asset)
      end

      if ticket.present?
        ticket.preferences[:snipeit] ||= {}
        ticket.preferences[:snipeit][:asset_ids] = seen_ids
        ticket.save!
      end

      { snipeit_assets: results }
    end
  end
end
