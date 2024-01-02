# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class KnowledgeBaseType < Gql::Types::BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Knowledge Base'

    field :iconset, String, null: false
    field :color_highlight, String, null: false
    field :color_header, String, null: false
    field :color_header_link, String, null: false
    field :homepage_layout, String, null: false
    field :category_layout, String, null: false
    field :active, Boolean, null: false
    field :custom_address, String
  end
end
