# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class KnowledgeBaseType < Gql::Types::BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields
    include Gql::Types::Concerns::HasPunditAuthorization
    include Gql::Types::Concerns::ResolvesKnowledgeBaseLocale

    description 'Knowledge Base'

    field :iconset, String, null: false
    field :color_highlight, String, null: false
    field :color_header, String, null: false
    field :color_header_link, String, null: false
    field :homepage_layout, String, null: false
    field :category_layout, String, null: false
    # The root lists categories and nothing else, so it has this one mode where a category has one
    #   per list (see KnowledgeBase::SORTING_MODES).
    field :category_sorting_mode, Gql::Types::Enum::KnowledgeBase::SortingModeType, null: false, description: 'How the top level categories of the knowledge base are ordered when browsed'
    field :active, Boolean, null: false
    field :custom_address, String

    # The texts of one locale are the translation's own, so they are read from it rather than
    #   through a `title(locale:)` of this type - like an answer's and a category's are.
    field :translation, Gql::Types::KnowledgeBase::TranslationType, null: true, description: 'The knowledge base in the given locale (falls back to the primary locale)' do
      argument :locale, String, required: false, description: 'System locale code to resolve the translation for; defaults to the locale the query was resolved in'
    end
    field :kb_locales, [Gql::Types::KnowledgeBase::LocaleType], null: false, description: 'Available locales, used for the language selector'
    # Carries the locale like the title does: it *is* the answer to "which locale did this resolve
    #   to", so one shared entry would tell a locale the answer of whichever was fetched last - and
    #   the section entry redirects on it (KnowledgeBase.vue).
    field :current_locale, Gql::Types::KnowledgeBase::LocaleType, null: true, description: 'Locale the content resolved to (given, else user-preferred, else primary)' do
      argument :locale, String, required: false, description: 'System locale code to resolve for; defaults to the locale the query was resolved in'
    end
    field :is_publicly_available, Boolean, null: false, description: 'Whether a public knowledge base with published content is reachable'
    # Not moved to the translation with the texts: it describes the content of the *browsed*
    #   locale, while the translation above may be a fallback from another one.
    field :is_visible_publicly, Boolean, null: false, description: 'Whether the public help site shows content in the given locale (drives the "view public knowledge base" link)' do
      argument :locale, String, required: false, description: 'System locale code to resolve for; defaults to the locale the query was resolved in'
    end
    field :show_feed_icon, Boolean, null: false, description: 'Whether the feeds are offered at all (admin setting "Show Feed Icon")'

    field :policy, Gql::Types::Policy::KnowledgeBaseType, null: false, method: :itself, description: 'Which actions the current user may perform on this knowledge base, including adding a top level category'

    # Null only for a knowledge base with no translation at all; a locale that has none of its own
    #   is answered from the primary locale.
    def translation(locale: nil)
      object.translation_preferred(requested_locale(locale))
    end

    def current_locale(locale: nil)
      requested_locale(locale)
    end

    def is_publicly_available
      object.active? && object.public_content?
    end

    def is_visible_publicly(locale: nil)
      object.active? && object.public_content?(requested_locale(locale))
    end

    def self.nested_access_pundit_method
      :show_any?
    end

    def self.direct_access_pundit_method
      :show_any?
    end

    private

    # The knowledge base a `locale` argument's code is looked up in - itself.
    def locale_knowledge_base
      object
    end
  end
end
