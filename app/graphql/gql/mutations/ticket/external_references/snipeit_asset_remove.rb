# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::ExternalReferences::SnipeitAssetRemove < BaseMutation
    description 'Remove a Snipe-IT asset from a ticket.'

    argument :ticket_id, GraphQL::Types::ID, loads: Gql::Types::TicketType, loads_pundit_method: :agent_update_access?, description: 'The related ticket for the Snipe-IT assets'
    argument :snipeit_asset_id, Integer, description: 'The Snipe-IT asset to remove'

    field :success, Boolean, description: 'Was the mutation successful?'

    def self.authorize(_obj, _ctx)
      Setting.get('snipeit_integration')
    end

    def resolve(snipeit_asset_id:, ticket: nil)
      ticket.preferences.dig(:snipeit, :asset_ids)&.map!(&:to_i)&.delete(snipeit_asset_id)
      ticket.save!

      { success: true }
    end
  end
end
