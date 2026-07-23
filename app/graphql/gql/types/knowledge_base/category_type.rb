# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::KnowledgeBase
  class CategoryType < Gql::Types::BaseObject
    include Gql::Types::Concerns::HasDefaultModelFields
    include Gql::Types::Concerns::HasPunditAuthorization

    description 'Knowledge Base Category'

    field :category_icon, String, null: false
    field :position, Integer, null: false

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

    belongs_to :parent, Gql::Types::KnowledgeBase::CategoryType
    belongs_to :knowledge_base, Gql::Types::KnowledgeBaseType, null: false

    def translations
      ::KnowledgeBase::Category::Translation.where(category_id: object.id)
    end

    def title
      titles = context[:knowledge_base_category_titles]
      return titles[object.id] if titles&.key?(object.id)

      object.translation_preferred(context[:knowledge_base_locale])&.title
    end

    def translation_missing
      missing = context[:knowledge_base_category_translation_missing]
      return missing[object.id] if missing&.key?(object.id)

      kb_locale.present? && object.translation_to(kb_locale).nil?
    end

    def visibility
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
