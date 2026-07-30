// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, toRef } from 'vue'

import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'

// Whether AI suggested answers are available to be shown in the ticket sidebar.
export const useAiSuggestedAnswersAvailability = () => {
  const config = toRef(useApplicationStore(), 'config')
  const { hasPermission } = useSessionStore()

  const showAiSuggestedAnswers = computed(
    () =>
      hasPermission('knowledge_base.*') &&
      hasPermission('ticket.agent') &&
      Boolean(config.value.ai_provider),
    // :TODO add missing setting
  )

  return { showAiSuggestedAnswers }
}
