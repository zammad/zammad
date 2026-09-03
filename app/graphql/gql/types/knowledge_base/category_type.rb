# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase
  class CategoryType < Gql::Types::BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields
    include Gql::Types::Concerns::HasPunditAuthorization
    include Gql::Types::Concerns::ResolvesKnowledgeBaseLocale

    description 'Knowledge Base Category'

    field :category_icon, String, null: false
    field :icon_set, Gql::Types::KnowledgeBase::IconSetType, null: false, description: 'Icon font of the knowledge base this category belongs to, needed to render `categoryIcon`'

    field :position, Integer, null: false
    # A mode per list, so the subcategories can be alphabetical while the answers are arranged by
    #   hand (see KnowledgeBase::SORTING_MODES).
    field :category_sorting_mode, Gql::Types::Enum::KnowledgeBase::SortingModeType, null: false, description: 'How the subcategories of this category are ordered when browsed'
    field :answer_sorting_mode, Gql::Types::Enum::KnowledgeBase::SortingModeType, null: false, description: 'How the answers of this category are ordered when browsed'

    field :translations, [Gql::Types::KnowledgeBase::Category::TranslationType], null: false

    # The category's name in one locale is the translation's own data, so it is read from the
    #   translation rather than through a `title(locale:)` of this type: a client caching by object
    #   identity then holds a record per locale instead of one field per argument, and the returned
    #   `kbLocale` says whether the name is this locale's own or a fallback.
    field :translation, Gql::Types::KnowledgeBase::Category::TranslationType, null: true, description: 'The category in the given locale (falls back to the primary locale)' do
      argument :locale, String, required: false, description: 'System locale code to resolve the translation for; defaults to the locale the query was resolved in'
    end

    # Not moved to the translation with the title, although these resolve from a locale too: they
    #   describe the category's content in the *browsed* locale, while the translation above may be
    #   a fallback from another one - a category whose answers are translated but whose own name is
    #   not would then report the fallback locale's state and counts.
    #   The argument is what keeps them apart in a client's cache, one entry per locale asked for.
    field :visibility, Gql::Types::Enum::KnowledgeBase::VisibilityType, null: false, description: 'Highest visibility of the content in this category and its subtree, in the given locale (untranslated content counts as draft)' do
      argument :locale, String, required: false, description: 'System locale code to resolve for; defaults to the locale the query was resolved in'
    end

    field :is_visible_publicly, Boolean, null: false, description: 'Whether this category shows published content in the given locale on the public help site (drives the "view public knowledge base" link)' do
      argument :locale, String, required: false, description: 'System locale code to resolve for; defaults to the locale the query was resolved in'
    end

    field :answer_count, Integer, null: false, description: 'Number of answers visible to the current user in this category and its whole subtree, in the given locale' do
      argument :locale, String, required: false, description: 'System locale code to count in; defaults to the locale the query was resolved in'
    end

    field :subcategory_count, Integer, null: false, description: 'Number of categories visible to the current user in this category and its whole subtree, in the given locale' do
      argument :locale, String, required: false, description: 'System locale code to count in; defaults to the locale the query was resolved in'
    end

    field :direct_answer_count, Integer, null: false, description: 'Number of answers visible to the current user directly in this category (its immediate level only), in the given locale' do
      argument :locale, String, required: false, description: 'System locale code to count in; defaults to the locale the query was resolved in'
    end

    field :direct_subcategory_count, Integer, null: false, description: 'Number of immediate child categories visible to the current user (its next level only), in the given locale' do
      argument :locale, String, required: false, description: 'System locale code to count in; defaults to the locale the query was resolved in'
    end

    field :breadcrumb, [Gql::Types::KnowledgeBase::CategoryType], null: false, description: 'Ancestors of this category, root first, including itself'
    field :is_deletable, Boolean, null: false, description: 'Whether this category is empty, i.e. whether deleting it would be refused because of subcategories or answers below it'

    field :policy, Gql::Types::Policy::KnowledgeBase::CategoryType, null: false, method: :itself, description: 'Which actions the current user may perform on this category'

    field :edited_at, GraphQL::Types::ISO8601DateTime, description: 'When the category was last edited in the requested locale, counting edits to the content below it'

    belongs_to :parent, Gql::Types::KnowledgeBase::CategoryType
    belongs_to :knowledge_base, Gql::Types::KnowledgeBaseType, null: false

    def translations
      ::KnowledgeBase::Category::Translation.where(category_id: object.id)
    end

    # Batched, so listing many categories of the same knowledge base does not
    #   cause one query per category.
    def icon_set
      Gql::RecordLoader
        .for(::KnowledgeBase)
        .load(object.knowledge_base_id)
        .then(&:iconset)
    end

    # Null only for a category with no translation at all; a locale that has none of its own is
    #   answered from the primary locale, like the public help site does.
    #
    # Batched by the browse and search queries, which ask this of every category they render; the
    #   fallback only runs where the type is resolved outside those flows (#translation_preferred
    #   queries per call).
    def translation(locale: nil)
      requested = requested_locale(locale)
      batched   = context[:knowledge_base_category_translations] if requested == query_locale

      return batched[object.id] if batched&.key?(object.id)

      object.translation_preferred(requested)
    end

    # The date is the preferred translation's own column, which the batch above already carries -
    #   so this reads it from there rather than through a batch of its own. Without one, dating a
    #   listing of categories would cost a query per card.
    def edited_at
      batched = context[:knowledge_base_category_translations]
      return batched[object.id]&.edited_at if batched&.key?(object.id)

      object.translation_preferred(query_locale)&.edited_at
    end

    # The search query batches this through a map of its own rather than through `category_details`:
    #   it needs the visibility of its category hits but none of the counts, and a details entry
    #   holding only this key would make the non-null count fields below resolve to nil.
    def visibility(locale: nil)
      requested    = requested_locale(locale)
      visibilities = context[:knowledge_base_category_visibility] if requested == query_locale

      return visibilities[object.id] if visibilities&.key?(object.id)

      detail = precomputed_detail if requested == query_locale

      detail&.dig(:visibility) || object.content_visibility(requested)
    end

    def answer_count(locale: nil)
      requested = requested_locale(locale)
      detail    = precomputed_detail if requested == query_locale

      return detail[:answer_count] if detail

      ::KnowledgeBase::Answer
        .visible_to_user(context.current_user, kb_locale: requested)
        .where(category_id: object.self_with_children_ids)
        .count
    end

    def subcategory_count(locale: nil)
      requested = requested_locale(locale)
      detail    = precomputed_detail if requested == query_locale

      return detail[:subcategory_count] if detail

      user = context.current_user

      (object.self_with_children - [object]).count { |category| category.visible_to_user?(user, requested) }
    end

    def direct_answer_count(locale: nil)
      requested = requested_locale(locale)
      detail    = precomputed_detail if requested == query_locale

      return detail[:direct_answer_count] if detail

      ::KnowledgeBase::Answer
        .visible_to_user(context.current_user, kb_locale: requested)
        .where(category_id: object.id)
        .count
    end

    def direct_subcategory_count(locale: nil)
      requested = requested_locale(locale)
      detail    = precomputed_detail if requested == query_locale

      return detail[:direct_subcategory_count] if detail

      user = context.current_user

      object.children.count { |category| category.visible_to_user?(user, requested) }
    end

    def breadcrumb
      precomputed = context[:knowledge_base_category_breadcrumbs]&.dig(object.id)
      return precomputed if precomputed

      object.self_with_parents.reverse
    end

    # Per-category counts and visibility precomputed in one batch by the browse
    #   query; nil when the type is resolved outside that flow.
    def precomputed_detail
      context[:knowledge_base_category_details]&.dig(object.id)
    end

    def is_visible_publicly(locale: nil)
      object.public_content?(requested_locale(locale))
    end

    # Deliberately not derived from `directSubcategoryCount` / `answerCount`: those are counts of
    #   what the *current user* may see, so they can read `0` for a category that `destroy!` will
    #   still refuse to delete. It is also kept orthogonal to `policy.destroy` — the action is shown
    #   when the user may delete, and explained when the category is not empty.
    #
    # Batched by the browse query, which asks this of every listed category; the fallback pair of
    #   existence checks only runs where the type is resolved outside that flow.
    def is_deletable
      detail = precomputed_detail
      return detail[:deletable] if detail

      !object.children.exists? && !object.answers.exists?
    end

    def self.nested_access_pundit_method
      :show_any?
    end

    # The type-level gate is the generic "may this category be exposed at all"
    #   check. Whether a category may actually be *browsed* in the requested
    #   locale is enforced per query in `resolve` (it needs the resolved locale,
    #   which Pundit cannot see at argument-load time).
    def self.direct_access_pundit_method
      :show_any?
    end

    private

    # The knowledge base a `locale` argument's code is looked up in.
    def locale_knowledge_base
      object.knowledge_base
    end
  end
end
