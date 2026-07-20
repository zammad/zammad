# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

    field :title, String, null: true, description: 'Title in the requested locale (falls back to the primary locale)'
    field :kb_locales, [Gql::Types::KnowledgeBase::LocaleType], null: false, description: 'Available locales, used for the language selector'
    field :current_locale, Gql::Types::KnowledgeBase::LocaleType, null: true, description: 'Locale the content resolved to (requested, else user-preferred, else primary)'
    field :is_publicly_available, Boolean, null: false, description: 'Whether a public knowledge base with published content is reachable'
    field :is_visible_publicly, Boolean, null: false, description: 'Whether the public help site shows content in the requested locale (drives the "view public knowledge base" link)'

    def title
      object.translation_preferred(context[:knowledge_base_locale])&.title
    end

    def current_locale
      context[:knowledge_base_locale]
    end

    def is_publicly_available
      object.active? && object.public_content?
    end

    def is_visible_publicly
      object.active? && object.public_content?(context[:knowledge_base_locale])
    end

    def self.nested_access_pundit_method
      :show_any?
    end

    def self.direct_access_pundit_method
      :show_any?
    end
  end
end
