# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class KnowledgeBase::Answers < BaseQuery
    include Gql::Concerns::HandlesKnowledgeBaseLocale

    description 'Fetch the paginated answers directly below a knowledge base category'

    argument :category_id, GraphQL::Types::ID, loads: Gql::Types::KnowledgeBase::CategoryType, description: 'Category whose answers to list'
    argument :locale, String, required: false, description: 'System locale code used to resolve titles'

    type Gql::Types::KnowledgeBase::AnswerType.connection_type, null: false

    def resolve(category:, locale: nil)
      # Only the active knowledge base is browsable — a category loaded by GID
      #   must not expose answers from an inactive knowledge base.
      return ::KnowledgeBase::Answer.none if !category.knowledge_base.active?

      store_knowledge_base_locale(category.knowledge_base, locale)

      # The type-level authorization is locale-agnostic; enforce the browsed
      #   locale here too, so a category hidden from this locale's listing cannot
      #   expose its answers directly (non-editors only).
      if !category.visible_to_user?(context.current_user, context[:knowledge_base_locale])
        raise Exceptions::Forbidden, "Category #{category.id} is not visible in the requested locale"
      end

      ::Service::KnowledgeBase::Answers
        .with_current_user(context.current_user)
        .execute(category:, locale: context[:knowledge_base_locale])
    end
  end
end
