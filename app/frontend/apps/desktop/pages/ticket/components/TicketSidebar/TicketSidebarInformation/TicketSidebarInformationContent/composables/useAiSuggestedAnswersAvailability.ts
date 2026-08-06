// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, toRef, toValue, type MaybeRefOrGetter } from 'vue'

import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'

// Whether AI suggested answers are available to be shown in the ticket sidebar.
//
// No knowledge base permission is required: the search only suggests answers the user may see, so
//   agents without knowledge base access are suggested published answers only (linked to their
//   public page, see useKnowledgeBaseAnswerLink).
//
// The agent check belongs to the ticket, not to the user: an agent can be the customer of a ticket
//   in a group they have no access to, and then only sees it in the customer view. The server
//   authorizes the search with the same agent read access, so asking for it without would fail.
export const useAiSuggestedAnswersAvailability = (
  hasAgentReadAccess: MaybeRefOrGetter<boolean>,
) => {
  const config = toRef(useApplicationStore(), 'config')
  const { hasPermission } = useSessionStore()

  const showAiSuggestedAnswers = computed(
    () =>
      toValue(hasAgentReadAccess) &&
      Boolean(config.value.ai_provider) &&
      Boolean(config.value.ai_assistance_kb_answer_suggestions),
  )

  const showRelevanceScore = computed(() =>
    hasPermission(['admin.ai_provider', 'admin.ai_knowledge_base']),
  )

  return { showAiSuggestedAnswers, showRelevanceScore }
}
