# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# frozen_string_literal: true

module Gql::Types
  class ChannelType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Channels'

    belongs_to :group, Gql::Types::GroupType

    field :area, String, null: false
    field :options, GraphQL::Types::JSON
    field :preferences, GraphQL::Types::JSON
    field :active, Boolean, null: false
    field :last_log_in, String
    field :last_log_out, String
    field :status_in, String
    field :status_out, String

    # GraphQL bypasses both the REST assets (CanSensitiveAssets#self_assets) and the
    # controller masking, so the secrets of Channel::SENSITIVE_FIELDS must be masked here.
    def options
      object.mask_sensitive_values({ 'options' => object.options }, object)['options']
    end
  end
end
