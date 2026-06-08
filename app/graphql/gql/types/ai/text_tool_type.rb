# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::AI
  class TextToolType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject
    include Gql::Types::Concerns::HasInternalIdField
    include Gql::Types::Concerns::HasInternalNoteField
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'AI::TextTool represents a tool that can be used to process text or HTML content using AI services.'

    field :name, String, null: false
    field :instruction, String, null: false
    field :active, Boolean, null: false

    field :groups, Gql::Types::GroupType.connection_type
  end
end
