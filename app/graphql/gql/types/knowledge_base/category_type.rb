# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase
  class CategoryType < Gql::Types::BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Knowledge Base Category'

    field :category_icon, String, null: false
    field :icon_set, Gql::Types::KnowledgeBase::IconSetType, null: false, description: 'Icon font of the knowledge base this category belongs to, needed to render `categoryIcon`'

    field :position, Integer, null: false
    # A mode per list, so the subcategories can be alphabetical while the answers are arranged by
    #   hand (see KnowledgeBase::SORTING_MODES).
    field :category_sorting_mode, Gql::Types::Enum::KnowledgeBase::SortingModeType, null: false, description: 'How the subcategories of this category are ordered when browsed'
    field :answer_sorting_mode, Gql::Types::Enum::KnowledgeBase::SortingModeType, null: false, description: 'How the answers of this category are ordered when browsed'

    field :translations, [Gql::Types::KnowledgeBase::Category::TranslationType], null: false

    field :title, String, null: true, description: 'Title in the requested locale (falls back to the primary locale)'
    field :translation_missing, Boolean, null: false, description: 'Whether the requested locale has no own translation for this category (its title is shown from a fallback locale)'
    field :visibility, Gql::Types::Enum::KnowledgeBase::VisibilityType, null: false, description: 'Highest visibility of the content in this category and its subtree, in the requested locale (untranslated content counts as draft)'
    field :is_visible_publicly, Boolean, null: false, description: 'Whether this category shows published content in the requested locale on the public help site (drives the "view public knowledge base" link)'
    field :answer_count, Integer, null: false, description: 'Number of answers visible to the current user in this category and its whole subtree'
    field :subcategory_count, Integer, null: false, description: 'Number of categories visible to the current user in this category and its whole subtree'
    field :direct_answer_count, Integer, null: false, description: 'Number of answers visible to the current user directly in this category (its immediate level only)'
    field :direct_subcategory_count, Integer, null: false, description: 'Number of immediate child categories visible to the current user (its next level only)'
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

    def title
      titles = context[:knowledge_base_category_titles]
      return titles[object.id] if titles&.key?(object.id)

      object.translation_preferred(context[:knowledge_base_locale])&.title
    end

    # Batched by the browse query alongside the title, and off the same translation — otherwise
    #   dating a listing of categories would cost one query per card.
    def edited_at
      timestamps = context[:knowledge_base_category_edited_at]
      return timestamps[object.id] if timestamps&.key?(object.id)

      object.translation_preferred(context[:knowledge_base_locale])&.edited_at
    end

    def translation_missing
      missing = context[:knowledge_base_category_translation_missing]
      return missing[object.id] if missing&.key?(object.id)

      kb_locale.present? && object.translation_to(kb_locale).nil?
    end

    # The search query batches this through a map of its own rather than through `category_details`:
    #   it needs the visibility of its category hits but none of the counts, and a details entry
    #   holding only this key would make the non-null count fields below resolve to nil.
    def visibility
      visibilities = context[:knowledge_base_category_visibility]
      return visibilities[object.id] if visibilities&.key?(object.id)

      precomputed_detail&.dig(:visibility) || object.content_visibility(kb_locale)
    end

    def answer_count
      detail = precomputed_detail
      return detail[:answer_count] if detail

      ::KnowledgeBase::Answer
        .visible_to_user(context.current_user, kb_locale:)
        .where(category_id: object.self_with_children_ids)
        .count
    end

    def subcategory_count
      detail = precomputed_detail
      return detail[:subcategory_count] if detail

      user = context.current_user

      (object.self_with_children - [object]).count { |category| category.visible_to_user?(user, kb_locale) }
    end

    def direct_answer_count
      detail = precomputed_detail
      return detail[:direct_answer_count] if detail

      ::KnowledgeBase::Answer
        .visible_to_user(context.current_user, kb_locale:)
        .where(category_id: object.id)
        .count
    end

    def direct_subcategory_count
      detail = precomputed_detail
      return detail[:direct_subcategory_count] if detail

      user = context.current_user

      object.children.count { |category| category.visible_to_user?(user, kb_locale) }
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

    def is_visible_publicly
      object.public_content?(kb_locale)
    end

    # Deliberately not derived from `directAnswerCount` / `directSubcategoryCount`: those are counts
    #   of what the *current user* may see, so they can read `0` for a category that `destroy!` will
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

    # The browsed locale, resolved by the query; content checks are scoped to it.
    def kb_locale
      context[:knowledge_base_locale]
    end
  end
end
