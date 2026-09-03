# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase::Answer
  class TranslationType < Gql::Types::BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields
    # Scoped, not the plain relations of `IsModelObject`: this record's `updated_by` *is* the editor
    #   of the text, the very person `edited_by` below is denied to a public reader - so the two have
    #   to be gated by the same scope, or one is a way around the other.
    include Gql::Types::Concerns::HasScopedModelUserRelations
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Knowledge Base Answer Translation'

    # A translation is one answer in one locale, so everything that depends on the locale resolves
    #   here without being asked for one - the object already names it (`kbLocale`). Which locale a
    #   caller *gets* is decided one level up, by `KnowledgeBaseAnswer#translation(locale:)`.
    field :title, String, null: false
    field :maybe_locale, String, description: 'Specified only for knowledge bases with multiple locales'
    field :visibility, Gql::Types::Enum::KnowledgeBase::VisibilityType, null: false, description: "Publication state of the translation's answer, used for color-coding"

    # The listing is the answers visible in this locale, so the position and the neighbours are of
    #   this translation rather than of the answer.
    #
    # A translation handed out as a fallback therefore reports its own locale's listing, not the
    #   browsed one - which is the same listing in every case that can happen: only editor access
    #   to the category hands out a fallback at all (a reader is refused the answer), and an
    #   editor's listing is not gated by locale (CanBePublished#visible_to_user). Pinned by
    #   'steps through the listing of the locale being browsed'.
    field :navigation, Gql::Types::KnowledgeBase::Answer::NavigationType, null: true, description: 'Position and neighbours of this answer within its category listing in this locale'

    # Contains all categories of the answer (already translated).
    field :category_tree_translation, [Gql::Types::KnowledgeBase::Category::TranslationType], null: false

    # The editorial lifecycle is internal: someone who only reaches this answer because it is
    #   published sees what the public site shows, not who last wrote the text or when.
    #   KnowledgeBase::AnswerPolicy#show? denies these fields for such a user, and
    #   Answer::TranslationPolicy delegates to it.
    scoped_fields do
      field :edited_at, GraphQL::Types::ISO8601DateTime, description: 'When this translation was last edited; only for users with internal access to the category'

      # Resolved from the translation's own `updated_by`, so it cannot use `belongs_to` - but it is
      #   a nested member of the authorized translation all the same.
      field :edited_by, Gql::Types::UserType, is_dependent_field: true, description: 'Last user that edited this translation; only for users with internal access to the category'
    end

    belongs_to :kb_locale, Gql::Types::KnowledgeBase::LocaleType, null: false
    belongs_to :answer, Gql::Types::KnowledgeBase::AnswerType, null: false
    belongs_to :content, Gql::Types::KnowledgeBase::Answer::Translation::ContentType, null: false

    def maybe_locale
      return if !KnowledgeBase.with_multiple_locales_exists?

      object.kb_locale.system_locale.locale.upcase
    end

    def visibility
      object.answer.visibility
    end

    def category_tree_translation
      object.answer.category.self_with_parents.map { |c| c.translation_preferred(object.kb_locale) }.reverse
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

    # Nulled rather than returned unauthorized: a role may grant knowledge base access without any
    #   ticket permission, and UserType would then raise on this nested user - turning a readable
    #   answer into a failed query.
    def edited_by
      user = object.updated_by
      return if user.nil?

      Pundit.policy(context.current_user, user).nested_show? ? user : nil
    end

    private

    def navigation_result
      @navigation_result ||= Service::KnowledgeBase::AnswerNavigation
        .with_current_user(context.current_user)
        .execute(answer: object.answer, locale: object.kb_locale, ids: navigation_sibling_ids)
    end

    # Takes the already-resolved navigation rather than fetching it again: reaching back to
    #   #navigation from here would recurse endlessly.
    def navigation_answers(navigation)
      ::KnowledgeBase::Answer
        .where(id: [navigation.previous_answer_id, navigation.next_answer_id])
        .includes(translations: :kb_locale)
        .index_by(&:id)
    end

    # Cached on the document rather than on this translation, because every answer of one category
    #   shares the listing of a locale.
    def navigation_sibling_ids
      cache = (context[:knowledge_base_answer_navigation_ids] ||= {})
      key = [object.answer.category_id, object.kb_locale_id]

      cache.fetch(key) do
        cache[key] = Service::KnowledgeBase::Answers
          .with_current_user(context.current_user)
          .execute(category: object.answer.category, locale: object.kb_locale)
          .except(:includes)
          .pluck(:id)
      end
    end
  end
end
