# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class KnowledgeBase::ContentUpdates < BaseSubscription
    description 'Ping emitted when knowledge base content changes, so browse views can refetch'

    # No `requires_permission`: browsing is wider than 'knowledge_base.*' (an active
    #   knowledge base with published content is open to any user), so this mirrors
    #   the browse queries and gates on the policies instead — see #update.

    field :knowledge_base, Gql::Types::KnowledgeBaseType, null: true, description: 'The active knowledge base; null once none is active'
    field :affected_category_ids, [GraphQL::Types::ID], null:        true,
                                                        description: 'IDs of the changed category and its ancestors (whose counts/visibility may change), limited to the ones visible to the subscriber; empty for knowledge-base-wide changes'

    # The actual changed data is per-user (visibility, granular permissions) and a
    #   single change invalidates tree-wide counts, so this stays a ping: subscribers
    #   refetch the scoped browse queries. `affectedCategoryIds` lets a client skip the
    #   refetch when the change is in a branch it is not currently viewing.
    def update(...)
      # Nil once no knowledge base is active — deliberately still a ping rather than `no_update`:
      #   deactivating one is itself a knowledge-base-wide change (KnowledgeBase includes
      #   TriggersKnowledgeBaseContentUpdates), and this is the only signal the browse views get for
      #   it. They refetch on it, the browse queries then answer not-found, and that is what takes
      #   them off content which is no longer browsable — swallowing the ping would leave it on
      #   screen instead.
      knowledge_base = ::KnowledgeBase.active.first

      categories = object.is_a?(Hash) ? Array(object[:categories]) : []

      # The same gate the browse queries apply to a category via `loads:`
      #   (Gql::Types::KnowledgeBase::CategoryType.direct_access_pundit_method), so a
      #   category the client can display is never filtered out here. Deliberately not
      #   `visible_to_user?`: that one is content- and locale-aware (this subscription
      #   has no locale), and it would drop a newly created, still empty category —
      #   which readers do need to see appear in their tree.
      visible_categories = categories.select { |category| pundit_authorized?(category, :show_any?) }

      # A change confined to categories this user may not see is none of their business,
      #   and their ids must not leak. The guard is on `categories` rather than on
      #   `visible_categories` alone because an empty list means "knowledge-base-wide
      #   change, refetch broadly" to the client — those changes carry no categories at
      #   all and must still reach everyone.
      return no_update if categories.any? && visible_categories.none?

      {
        knowledge_base:,
        affected_category_ids: visible_categories.map { |category| Gql::ZammadSchema.id_from_object(category) },
      }
    end
  end
end
