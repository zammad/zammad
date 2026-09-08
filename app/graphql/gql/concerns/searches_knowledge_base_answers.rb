# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Knowledge base answers are a searchable model of the generic search, but they are deliberately
#   *not* served by Service::Search.
#
# KnowledgeBase::Answer::Translation::Search#search_preferences returns false for anyone without
#   `knowledge_base.*`, which is what keeps the knowledge base out of the legacy interface's generic
#   search - and it is meant to stay there (zammad/coordination-desktop-view#873, the PO's answer to
#   its second clarification). Widening it would change what the legacy search returns to customers,
#   which is a breaking change nobody asked for.
#
# So this one model is routed to the knowledge base's own search service instead. That service
#   applies the knowledge base's visibility rules (KnowledgeBase::Answer.visible_to_user, keyed on
#   the flavor it derives per user) and its own ranking, including the title and tag weighting for
#   agents - which is exactly what the story asks for, and what a generic Elasticsearch query over
#   the same index would not do.
#
# The cost is one special case in a generic query. It is a decision, not an oversight: do not
#   "simplify" it back into Service::Search.
module Gql::Concerns::SearchesKnowledgeBaseAnswers
  extend ActiveSupport::Concern

  include Gql::Concerns::HandlesKnowledgeBaseLocale

  MODEL = ::KnowledgeBase::Answer::Translation

  private

  def knowledge_base_answers?(model)
    model == MODEL
  end

  # The translations the user may see, ranked by the knowledge base's backend and bounded by the
  #   service's own result cap - so the size of this list is the lower bound the story's AC10
  #   describes, not an exact total.
  #
  # nil when there is no active knowledge base to search. Deliberately not a raise, unlike the
  #   knowledge base's own queries (see .dev/agent_docs/knowledge_base_patterns.md): quicksearch asks
  #   for all four searchable entities in one document, so raising here would take the ticket, user
  #   and organization groups down with it on every instance that has no knowledge base.
  def knowledge_base_answer_hits(query)
    knowledge_base = ::KnowledgeBase.active.first
    return if knowledge_base.nil?

    # No locale argument reaches the generic search, so the user's preferred locale is resolved for
    #   them - the same one their knowledge base browsing uses. Stored on the context because it is
    #   scoped to this field's subtree, which is what makes the aliased quicksearch document safe.
    store_knowledge_base_locale(knowledge_base, nil)

    ::Service::KnowledgeBase::Search
      .with_current_user(context.current_user)
      .execute(
        query:          query,
        knowledge_base: knowledge_base,
        locale:         context[:knowledge_base_locale],
        indexes:        [MODEL.name],
        enriched:       false,
      )
      .results
      .map(&:translation)
  end
end
