# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Ticket::ExternalReferences
  class SnipeitAssetType < Gql::Types::BaseObject
    description 'Snipe-IT asset item for an external reference for a ticket'

    field :snipeit_asset_id, Integer, null: false, method: :id, description: 'Snipe-IT asset id'
    field :name, String, null: false
    field :asset_tag, String, description: 'Asset tag'
    field :serial, String, description: 'Serial number'
    field :link, Gql::Types::UriHttpStringType, description: 'Link to the asset in the Snipe-IT GUI'
    field :model, String, description: 'Asset model name', method: :model_name
    field :status, String, description: 'Asset status', method: :status_name
    field :category, String, description: 'Asset category', method: :category_name
    field :location, String, description: 'Asset location', method: :location_name
  end
end
