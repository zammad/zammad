# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::ExternalReferences::SnipeitAssetRemove < BaseMutation
    description 'Remove a Snipe-IT asset from a ticket.'

    argument :ticket_id, GraphQL::Types::ID, loads: Gql::Types::TicketType, loads_pundit_method: :agent_update_access?, description: 'The related ticket for the Snipe-IT assets'
    argument :snipeit_asset_id, Integer, description: 'The Snipe-IT asset to remove'

    field :success, Boolean, description: 'Was the mutation successful?'

    requires_enabled_setting 'snipeit_integration', error_message: __('Snipe-IT integration is not enabled')

    def resolve(snipeit_asset_id:, ticket: nil)
      remaining_asset_ids = Array(ticket.preferences.dig(:snipeit, :asset_ids)).map(&:to_i) - [snipeit_asset_id]

      Service::Ticket::ExternalReferences::Snipeit::LinkAssets
        .with_current_user(context.current_user)
        .execute(ticket: ticket, asset_ids: remaining_asset_ids)

      { success: true }
    end
  end
end
