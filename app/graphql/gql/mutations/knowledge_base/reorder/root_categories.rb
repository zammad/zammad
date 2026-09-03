# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  # The top level of the tree, whose sorting mode is stored on the knowledge base itself — which
  #   lists categories only, and so carries the category mode alone. Its own
  #   mutation rather than KnowledgeBaseReorderCategories with an optional parent, so the argument
  #   that names the node stays required where there is one — the three scopes mirror the three
  #   endpoints the legacy interface has for them (KnowledgeBase::CategoriesController).
  class KnowledgeBase::Reorder::RootCategories < KnowledgeBase::Base
    include Gql::Concerns::HandlesKnowledgeBaseLocale

    description 'Set how the top level categories of the knowledge base are ordered, and store their hand-made order.'

    argument :sorting_mode, Gql::Types::Enum::KnowledgeBase::SortingModeType, description: 'How the top level categories are to be ordered from now on.'

    # Required with `manual` and refused with anything else, so the mode and the order it is read
    #   back in are always stored together — and every drag afterwards sends the whole order again.
    #
    # Deliberately no `loads:`: the records are not needed here, only their order. Loading them
    #   would ask every listed category's policy for a question the node's own gate has already
    #   answered — a whole list of them, on every drag — and an id that is not part of the scope is
    #   refused by the service, which is the only check that can tell. A GID of another type is
    #   dropped while the ids are read, which leaves the list incomplete: the same refusal.
    argument :category_ids, [GraphQL::Types::ID], required: false, description: 'All top level categories, in the wanted order. Required with `manual`, refused with any other mode, and always complete.'

    field :knowledge_base, Gql::Types::KnowledgeBaseType, null: true, description: 'The knowledge base with its updated `categorySortingMode`.'

    # Deliberately no field for the reordered categories: the new order is not this payload's to
    #   render. Every write here pings `knowledgeBaseContentUpdates` (both models include
    #   TriggersKnowledgeBaseContentUpdates), on which the browse view refetches its listing — where
    #   the category type resolves its counts and titles from one batched result rather than once per
    #   category, as it would have to here.
    def resolve(sorting_mode:, category_ids: nil)
      ordered_ids = category_ids && Gql::ZammadSchema.internal_ids_from_ids(category_ids, type: ::KnowledgeBase::Category)

      updated = Service::KnowledgeBase::Reorder::Categories
        .with_current_user(context.current_user)
        .execute(sorting_mode:, ordered_ids:)

      # No locale is asked of the caller — a sorting mode has nothing to do with one — but the
      #   knowledge base that is rendered back carries locale-dependent fields all the same, so the
      #   payload is localized the way every knowledge base read without an explicit locale is: in
      #   the current user's preferred locale.
      store_knowledge_base_locale(updated, nil)

      { knowledge_base: updated }
    rescue Exceptions::UnprocessableContent => e
      error_response({ message: e.message })
    end
  end
end
