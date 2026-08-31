# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase
  class AnswerType < Gql::Types::BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields
    include Gql::Types::Concerns::HasScopedModelUserRelations
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Knowledge Base Answer'

    field :position, Integer, null: false

    # Everybody who reaches the answer is told this, unlike the two dates in `scoped_fields` below:
    #   that it is published, and when, is what the public site shows. Filtered to a date that has
    #   been reached all the same (see #editorial_date), which for such a user it always has - they
    #   reach a published answer only once its date has passed.
    field :published_at, GraphQL::Types::ISO8601DateTime, description: 'When the answer was published; only once reached unless the user may edit it'

    # Non-null, like every other `title` of the taskbar item entity union
    #   (Gql::Types::User::TaskbarItemEntityType) — GraphQL requires one response name to have one
    #   response shape across a document, disjoint union members included, and an answer's tab
    #   selects this field beside a ticket's. Blank only for an answer without a single translation,
    #   which the client renders its own fallback label for; a *missing* translation in the requested
    #   locale is `translationMissing`, not an absent title.
    field :title, String, null: false, description: 'Title in the requested locale (falls back to the primary locale)'
    field :content, Gql::Types::KnowledgeBase::Answer::Translation::ContentType, null: true, description: 'Body of the translation in the requested locale (falls back to the primary locale, like the title)'
    field :translation_id, GraphQL::Types::ID, description: 'ID of the translation in the requested locale (falls back to the primary locale, like the title)'
    field :translation_missing, Boolean, null: false, description: 'Whether the requested locale has no own translation for this answer (its title is shown from a fallback locale)'
    field :visibility, Gql::Types::Enum::KnowledgeBase::VisibilityType, null: false, description: 'Publication state, used for color-coding'

    # Derived from the same three dates as `visibility` rather than left to the client: which change
    #   is still ahead is a question about how the state is derived from them
    #   (CanBePublished#visibility_schedules), and answering it here keeps one source of truth for the
    #   widget that shows them and the mutations that write them.
    #
    # Not in `scoped_fields`, because the rule is not "whose field is this" but the same one the
    #   dates follow: whoever may see a date that has not been reached is told what it means, and
    #   that is an editor. Its resolver says so - see #visibility_schedules.
    field :visibility_schedules, [Gql::Types::KnowledgeBase::Answer::VisibilityScheduleType, { null: false }], description: 'Visibility changes the answer is going to make, in the order they take effect; only for users who may edit the answer'

    field :navigation, Gql::Types::KnowledgeBase::Answer::NavigationType, null:        true,
                                                                          description: 'Position and neighbours of this answer within its category listing'

    field :tags, [String, { null: false }], method: :tag_list, description: 'Assigned tags'

    # There is no per-record gate for an answer otherwise: `knowledge_base.editor` is global, while
    #   granular permissions can leave the same user an editor of one subtree and a reader of the
    #   next — so an edit action has to be offered per answer. Its `update` / `destroy` are
    #   KnowledgeBase::AnswerPolicy#update? / #destroy?, i.e. editor access to the answer's category.
    field :policy, Gql::Types::Policy::DefaultType, null: false, method: :itself, description: 'Which actions the current user may perform on this answer'

    # The answer's own attachments, not the translation content's: the latter holds the
    #   body's inline images, which the reader already renders inside the body.
    field :attachments, [Gql::Types::StoredFileType, { null: false }], null:        false,
                                                                       method:      :attachments_sorted,
                                                                       description: 'Files attached to the answer, sorted by file name; locale-independent, and without the inline images of the translation body'

    # The editorial lifecycle is internal: someone who only reaches this answer because
    #   it is published sees what the public site shows — that it is published, and
    #   when — but not when it went internal, was archived, or who last edited it.
    #   AnswerPolicy#show? denies these fields for such a user.
    #
    # How much of a date they are told is a second question, and this block does not answer it: only
    #   an editor is given one that has not been reached yet — see #editorial_date.
    scoped_fields do
      field :archived_at, GraphQL::Types::ISO8601DateTime, description: 'Only for users with internal access to the category; the public site knows publication only. Only once reached unless the user may edit the answer'
      field :internal_at, GraphQL::Types::ISO8601DateTime, description: 'Only for users with internal access to the category; the public site knows publication only. Only once reached unless the user may edit the answer'
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
      preferred_translation&.title.to_s
    end

    def content
      preferred_translation&.content
    end

    def translation_id
      translation = preferred_translation
      return if translation.nil?

      Gql::ZammadSchema.id_from_object(translation)
    end

    # The publication dates, filtered for anybody but an editor of the category: a date still ahead is
    #   a *scheduled* transition, and what an answer is going to become is editorial - which is why
    #   `visibility_schedules` is denied to them (KnowledgeBase::AnswerPolicy#show?). Without the
    #   same filter here that schedule would simply be read off the raw column instead.
    #
    # An editor gets the columns as they are: their views show what is in effect beside what is
    #   scheduled, and telling the two apart is the client's business there.
    def internal_at
      editorial_date(:internal)
    end

    def published_at
      editorial_date(:published)
    end

    def archived_at
      editorial_date(:archived)
    end

    # Null rather than empty for anybody who may not edit the answer: they are not told the dates
    #   these are derived from either, so there is nothing to report - as opposed to "nothing is
    #   scheduled", which is what an empty list says to an editor.
    def visibility_schedules
      object.visibility_schedules if editor?
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

    # @param state [Symbol] one of CanBePublished::SCHEDULABLE_VISIBILITIES' keys
    def editorial_date(state)
      date = object[CanBePublished::SCHEDULABLE_VISIBILITIES.fetch(state)]

      return date if editor?

      # The model's own definition of "still ahead", so this filter and the schedule it keeps hidden
      #   cannot drift apart.
      object.visibility_scheduled_at(state).nil? ? date : nil
    end

    # Editor access to this answer's category, which is what KnowledgeBase::AnswerPolicy#update?
    #   answers. Memoized: it is asked once per date field, and resolving it walks the category tree.
    def editor?
      return @editor if defined?(@editor)

      @editor = Pundit.policy(context.current_user, object).update?
    end

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
