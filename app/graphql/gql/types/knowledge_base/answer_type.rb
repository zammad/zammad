# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase
  class AnswerType < Gql::Types::BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields
    include Gql::Types::Concerns::HasScopedModelUserRelations
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Knowledge Base Answer'

    field :position, Integer, null: false
    field :published_at, GraphQL::Types::ISO8601DateTime

    field :title, String, null: true, description: 'Title in the requested locale (falls back to the primary locale)'
    field :content, Gql::Types::KnowledgeBase::Answer::Translation::ContentType, null: true, description: 'Body of the translation in the requested locale (falls back to the primary locale, like the title)'
    field :translation_id, GraphQL::Types::ID, description: 'ID of the translation in the requested locale (falls back to the primary locale, like the title)'
    field :translation_missing, Boolean, null: false, description: 'Whether the requested locale has no own translation for this answer (its title is shown from a fallback locale)'
    field :visibility, Gql::Types::Enum::KnowledgeBase::VisibilityType, null: false, description: 'Publication state, used for color-coding'

    field :navigation, Gql::Types::KnowledgeBase::Answer::NavigationType, null:        true,
                                                                          description: 'Position and neighbours of this answer within its category listing'

    field :tags, [String, { null: false }], method: :tag_list, description: 'Assigned tags'

    # The answer's own attachments, not the translation content's: the latter holds the
    #   body's inline images, which the reader already renders inside the body.
    field :attachments, [Gql::Types::StoredFileType, { null: false }], null:        false,
                                                                       method:      :attachments_sorted,
                                                                       description: 'Files attached to the answer, sorted by file name; locale-independent, and without the inline images of the translation body'

    # The editorial lifecycle is internal: someone who only reaches this answer because
    #   it is published sees what the public site shows — that it is published, and
    #   when — but not when it went internal, was archived, or who last edited it.
    #   AnswerPolicy#show? denies these fields for such a user.
    scoped_fields do
      field :archived_at, GraphQL::Types::ISO8601DateTime, description: 'Only for users with internal access to the category; the public site knows publication only'
      field :internal_at, GraphQL::Types::ISO8601DateTime, description: 'Only for users with internal access to the category; the public site knows publication only'
      field :edited_at, GraphQL::Types::ISO8601DateTime, description: 'When the translation in the requested locale was last edited; only for users with internal access to the category'

      # Resolved from the translation instead of an own foreign key, so it cannot use
      #   `belongs_to` — but it is a nested member of the authorized answer all the same.
      field :edited_by, Gql::Types::UserType, is_dependent_field: true, description: 'Last user that edited the translation in the requested locale; only for users with internal access to the category'
    end

    belongs_to :category, Gql::Types::KnowledgeBase::CategoryType, null: false
    belongs_to :archived_by, Gql::Types::UserType, null: true
    belongs_to :internal_by, Gql::Types::UserType, null: true
    belongs_to :published_by, Gql::Types::UserType, null: true

    def title
      preferred_translation&.title
    end

    def content
      preferred_translation&.content
    end

    def translation_id
      translation = preferred_translation
      return if translation.nil?

      Gql::ZammadSchema.id_from_object(translation)
    end

    def translation_missing
      locale = context[:knowledge_base_locale]
      locale.present? && loaded_translations.none? { |translation| translation.kb_locale_id == locale.id }
    end

    def navigation
      navigation = navigation_result
      return if navigation.nil?

      answers = navigation_answers(navigation)

      {
        index:           navigation.index,
        total_count:     navigation.total_count,
        previous_answer: answers.fetch(navigation.previous_answer_id),
        next_answer:     answers.fetch(navigation.next_answer_id),
      }
    end

    # The answer's own `updated_at`/`updated_by` are unreliable here: a translation
    #   `touch`es its answer without running callbacks, so the timestamp moves while
    #   `updated_by_id` stays behind. The translation's own edit metadata is what the
    #   reader shows, and it is locale-aware.
    def edited_at
      preferred_translation&.edited_at
    end

    # Nulled rather than returned unauthorized: a role may grant knowledge base access
    #   without any ticket permission, and UserType would then raise on this nested
    #   user — turning a readable answer into a failed query.
    def edited_by
      user = preferred_translation&.updated_by
      return if user.nil?

      Pundit.policy(context.current_user, user).nested_show? ? user : nil
    end

    private

    def navigation_result
      return @navigation_result if defined?(@navigation_result)

      @navigation_result = Service::KnowledgeBase::AnswerNavigation
        .with_current_user(context.current_user)
        .execute(answer: object, locale: kb_locale, ids: navigation_sibling_ids)
    end

    # Takes the already-resolved navigation rather than fetching it again: reaching
    #   back to #navigation from here would recurse endlessly.
    def navigation_answers(navigation)
      @navigation_answers ||= ::KnowledgeBase::Answer
        .where(id: [navigation.previous_answer_id, navigation.next_answer_id])
        .includes(translations: :kb_locale)
        .index_by(&:id)
    end

    def navigation_sibling_ids
      cache = (context[:knowledge_base_answer_navigation_ids] ||= {})
      key = [object.category_id, kb_locale&.id]

      cache.fetch(key) do
        cache[key] = Service::KnowledgeBase::Answers
          .with_current_user(context.current_user)
          .execute(category: object.category, locale: kb_locale)
          .except(:includes)
          .pluck(:id)
      end
    end

    def kb_locale
      context[:knowledge_base_locale]
    end

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
