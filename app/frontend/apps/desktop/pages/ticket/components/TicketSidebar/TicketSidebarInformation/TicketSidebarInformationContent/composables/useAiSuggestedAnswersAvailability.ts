// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, toRef } from 'vue'

import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'

// Whether AI suggested answers are available to be shown in the ticket sidebar.
//
// No knowledge base permission is required: the search only suggests answers the user may see, so
//   agents without knowledge base access are suggested published answers only (linked to their
//   public page, see useKnowledgeBaseAnswerLink).
export const useAiSuggestedAnswersAvailability = () => {
  const config = toRef(useApplicationStore(), 'config')
  const { hasPermission } = useSessionStore()

  const showAiSuggestedAnswers = computed(
    () =>
      hasPermission('ticket.agent') &&
      Boolean(config.value.ai_provider) &&
      Boolean(config.value.ai_assistance_kb_answer_suggestions),
  )

  const showRelevanceScore = computed(() =>
    hasPermission(['admin.ai_provider', 'admin.ai_knowledge_base']),
  )

  return { showAiSuggestedAnswers, showRelevanceScore }
}
