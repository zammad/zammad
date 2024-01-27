# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# frozen_string_literal: true

module Gql::Types
  class EmailAddressType < BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasPunditAuthorization
    include Gql::Types::Concerns::HasInternalNoteField

    description 'EmailAddress model instances'

    belongs_to :channel, Gql::Types::ChannelType

    field :name, String, null: false
    field :email, String, null: false
    field :active, Boolean, null: false
    field :preferences, GraphQL::Types::JSON
  end
end
