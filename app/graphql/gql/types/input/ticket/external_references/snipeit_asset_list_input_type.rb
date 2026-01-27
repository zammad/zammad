# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::Ticket::ExternalReferences
  class SnipeitAssetListInputType < Gql::Types::BaseInputObject
    description 'Input fields for retrieving Snipe-IT asset details'

    argument :ticket_id, GraphQL::Types::ID, required: false, loads: Gql::Types::TicketType, description: 'The related ticket for the Snipe-IT assets'
    argument :snipeit_asset_ids, [Integer], required: false, description: 'Snipe-IT asset IDs to fetch'

    validates required: { one_of: %i[ticket snipeit_asset_ids] }
  end
end
