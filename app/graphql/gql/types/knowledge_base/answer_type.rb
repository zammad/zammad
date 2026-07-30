# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase
  class AnswerType < Gql::Types::BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields
    include Gql::Types::Concerns::HasScopedModelUserRelations
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Knowledge Base Answer'

    field :position, Integer, null: false
    field :archived_at, GraphQL::Types::ISO8601DateTime
    field :internal_at, GraphQL::Types::ISO8601DateTime
    field :published_at, GraphQL::Types::ISO8601DateTime

    field :title, String, null: true, description: 'Title in the requested locale (falls back to the primary locale)'
    field :translation_missing, Boolean, null: false, description: 'Whether the requested locale has no own translation for this answer (its title is shown from a fallback locale)'
    field :visibility, Gql::Types::Enum::KnowledgeBase::VisibilityType, null: false, description: 'Publication state, used for color-coding'

    field :tags, [String, { null: false }], method: :tag_list, description: 'Assigned tags'

    belongs_to :category, Gql::Types::KnowledgeBase::CategoryType, null: false
    belongs_to :archived_by, Gql::Types::UserType, null: true
    belongs_to :internal_by, Gql::Types::UserType, null: true
    belongs_to :published_by, Gql::Types::UserType, null: true

    def title
      preferred_translation&.title
    end

    def translation_missing
      locale = context[:knowledge_base_locale]
      locale.present? && loaded_translations.none? { |translation| translation.kb_locale_id == locale.id }
    end

    private

    # Eager-loaded by Service::KnowledgeBase::Answers, so title/translation_missing
    #   iterate in memory instead of querying per answer.
    def loaded_translations
      object.translations
    end

    # Mirrors KnowledgeBase::Answer#translation_preferred (requested locale, then
    #   the primary locale, then any), resolved from the eager-loaded set.
    def preferred_translation
      locale = context[:knowledge_base_locale]

      (locale && loaded_translations.find { |translation| translation.kb_locale_id == locale.id }) ||
        loaded_translations.find { |translation| translation.kb_locale.primary? } ||
        loaded_translations.first
    end
  end
end
