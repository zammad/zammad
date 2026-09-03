# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase
  class AnswerType < Gql::Types::BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields
    include Gql::Types::Concerns::HasScopedModelUserRelations
    include Gql::Types::Concerns::HasPunditAuthorization
    include Gql::Types::Concerns::ResolvesKnowledgeBaseLocale

    description 'Knowledge Base Answer'

    field :position, Integer, null: false

    # Everybody who reaches the answer is told this, unlike the two dates in `scoped_fields` below:
    #   that it is published, and when, is what the public site shows. Filtered to a date that has
    #   been reached all the same (see #editorial_date), which for such a user it always has - they
    #   reach a published answer only once its date has passed.
    field :published_at, GraphQL::Types::ISO8601DateTime, description: 'When the answer was published; only once reached unless the user may edit it'

    # Everything that depends on the locale lives on the translation this returns - its title, its
    #   body, its editorial metadata and its place in the listing. What stays on the answer is
    #   language-independent: the state, the dates, the tags, the files, the category.
    #
    # The locale is an argument of this field, not only of the query it sits in: a client that
    #   caches by object identity keys a field by the arguments it was asked with, so without one an
    #   answer would point at a single translation - whichever locale was fetched last. Optional, so
    #   that callers asking for none share the reader's preferred locale coherently.
    #
    # Null only for an answer with no translation at all. A locale that has none of its own is
    #   answered with the fallback (primary, then any), which a caller tells apart by comparing the
    #   returned `kbLocale` with the one it asked for.
    field :translation, Gql::Types::KnowledgeBase::Answer::TranslationType, null: true, description: 'The answer in the given locale (falls back to the primary locale)' do
      argument :locale, String, required: false, description: 'System locale code to resolve the translation for; defaults to the locale the query was resolved in'
    end

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
    end

    belongs_to :category, Gql::Types::KnowledgeBase::CategoryType, null: false
    belongs_to :archived_by, Gql::Types::UserType, null: true
    belongs_to :internal_by, Gql::Types::UserType, null: true
    belongs_to :published_by, Gql::Types::UserType, null: true

    def translation(locale: nil)
      preferred_translation(requested_locale(locale))
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

    # Eager-loaded by Service::KnowledgeBase::Answers, so resolving the translation of a listed
    #   answer iterates in memory instead of querying per answer.
    def loaded_translations
      object.translations
    end

    # The knowledge base a `locale` argument's code is looked up in.
    def locale_knowledge_base
      object.category.knowledge_base
    end

    # Mirrors KnowledgeBase::Answer#translation_preferred (requested locale, then
    #   the primary locale, then any), resolved from the eager-loaded set.
    def preferred_translation(locale = query_locale)
      (locale && loaded_translations.find { |translation| translation.kb_locale_id == locale.id }) ||
        loaded_translations.find { |translation| translation.kb_locale.primary? } ||
        loaded_translations.first
    end
  end
end
