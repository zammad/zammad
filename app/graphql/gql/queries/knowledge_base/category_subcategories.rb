# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class KnowledgeBase::CategorySubcategories < BaseQueryWithPayload
    include Gql::Concerns::HandlesKnowledgeBaseLocale

    description 'Fetch a knowledge base node: its breadcrumb and the visible child categories (subcategories)'

    argument :category_id, GraphQL::Types::ID, required: false, loads: Gql::Types::KnowledgeBase::CategoryType, description: 'Category to open; omit for the knowledge base root'
    argument :locale, String, required: false, description: 'System locale code used to resolve titles'

    field :category, Gql::Types::KnowledgeBase::CategoryType, null: true, description: 'The opened category (null at the knowledge base root); read its `breadcrumb` field for the header'
    field :subcategories, [Gql::Types::KnowledgeBase::CategoryType], null: false, description: 'Child categories visible to the current user, each carrying its own breadcrumb'

    def resolve(category: nil, locale: nil)
      knowledge_base = category&.knowledge_base || active_knowledge_base

      # Only the active knowledge base is browsable — a category loaded by GID
      #   must not expose content from an inactive knowledge base.
      return { category: nil, subcategories: [] } if knowledge_base.nil? || !knowledge_base.active?

      store_knowledge_base_locale(knowledge_base, locale)

      # The type-level authorization is locale-agnostic (Pundit cannot see the
      #   locale at argument-load time). Enforce the browsed locale here — the
      #   authoritative gate — so a category hidden from this locale's listing
      #   cannot be opened directly by URL (non-editors only; editors see
      #   untranslated content).
      if category && !category.visible_to_user?(context.current_user, context[:knowledge_base_locale])
        raise Exceptions::Forbidden, "Category #{category.id} is not visible in the requested locale"
      end

      result = ::Service::KnowledgeBase::CategoryContent
        .with_current_user(context.current_user)
        .execute(knowledge_base:, category:, locale: context[:knowledge_base_locale])

      # Hand the batched per-category data to the category type so it resolves
      #   counts, visibility, titles, and breadcrumbs without querying per
      #   category. Scoped to this query's subtree (see store_knowledge_base_locale).
      context.scoped_set!(:knowledge_base_category_details, result[:category_details])
      context.scoped_set!(:knowledge_base_category_titles, result[:category_titles])
      context.scoped_set!(:knowledge_base_category_translation_missing, result[:category_translation_missing])
      context.scoped_set!(:knowledge_base_category_breadcrumbs, result[:category_breadcrumbs])

      result.slice(:category, :subcategories)
    end
  end
end
